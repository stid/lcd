#!/usr/bin/env bash
# Tests for the closeout-evaluator replay instrument (work-item: evaluator-exec, harness D-034).
# Covers the frozen dataset (evals/evaluator-replay/), the runner (evals/replay-evaluator.sh)
# against a fake model binary that performs real side effects, and the evaluator doc wording.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
dataset="$plugin_root/evals/evaluator-replay"
runner="$plugin_root/evals/replay-evaluator.sh"

command -v jq >/dev/null 2>&1 || fail "jq required"
init_tmpdir

# --- AC-6 (EVAL): replay dataset integrity ------------------------------------------------
cases="$dataset/cases.json"
[[ -f "$cases" ]] || fail "AC-6 (EVAL): dataset manifest missing: $cases"
jq -e . "$cases" >/dev/null || fail "AC-6 (EVAL): cases.json does not parse"
for id in standard-1 standard-2 standard-3 deep-1 deep-2 deep-3; do
  jq -e --arg id "$id" 'map(select(.id == $id)) | length == 1' "$cases" >/dev/null \
    || fail "AC-6 (EVAL): case $id missing or duplicated"
done
while IFS=$'\t' read -r id bundle prompt checkout; do
  b="$dataset/$bundle"; p="$dataset/$prompt"
  [[ -f "$b" ]] || fail "AC-6 (EVAL): $id bundle missing: $bundle"
  [[ -f "$p" ]] || fail "AC-6 (EVAL): $id prompt missing: $prompt"
  heads="$(git bundle list-heads "$b" 2>/dev/null)" || fail "AC-6 (EVAL): $id bundle unreadable"
  # Truncation: the bundle carries exactly the case refs, each tip at the case commit.
  nrefs="$(jq -r --arg id "$id" '.[] | select(.id == $id) | .refs | length' "$cases")"
  [[ "$(grep -c . <<<"$heads")" -eq "$nrefs" ]] \
    || fail "AC-6 (EVAL): $id bundle refs != case refs (post-dispatch history leaks?)
$heads"
  while IFS=$'\t' read -r ref sha; do
    grep -Eq "^${sha}[0-9a-f]* refs/heads/${ref}\$" <<<"$heads" \
      || fail "AC-6 (EVAL): $id ref $ref not at $sha in bundle"
  done < <(jq -r --arg id "$id" '.[] | select(.id == $id) | .refs | to_entries[] | "\(.key)\t\(.value)"' "$cases")
  jq -e --arg id "$id" '.[] | select(.id == $id) | .refs[.checkout] != null' "$cases" >/dev/null \
    || fail "AC-6 (EVAL): $id checkout ref $checkout not among its refs"
  # No post-dispatch commit: nothing in the history mentions the evaluator's findings.
  clone="$tmp/integrity-$id"
  git clone -q "$b" "$clone" 2>/dev/null || fail "AC-6 (EVAL): $id bundle does not clone"
  if git -C "$clone" log --all --format=%B | grep -qi 'evaluator'; then
    fail "AC-6 (EVAL): $id history mentions the evaluator (post-dispatch commit leaked)"
  fi
  # Prompts are templated and carry no machine paths (plugin stays self-contained).
  grep -q '{ROOT}' "$p" || fail "AC-6 (EVAL): $id prompt is not {ROOT}-templated"
  if grep -Eq '/Users/|/home/' "$p"; then fail "AC-6 (EVAL): $id prompt has a machine path"; fi
done < <(jq -r '.[] | "\(.id)\t\(.bundle)\t\(.prompt)\t\(.checkout)"' "$cases")
# Labels: the known survivor and the three D-028 challenges the bar measures.
for id in standard-3 deep-3; do
  jq -e --arg id "$id" '.[] | select(.id == $id) | .known_defects | map(.id) | index("checksum-first-record")' \
    "$cases" >/dev/null || fail "AC-6 (EVAL): $id lacks the checksum-first-record label"
done
jq -e '.[] | select(.id == "standard-2") | .d028_found | index("lastUpdated-advance")' "$cases" >/dev/null \
  || fail "AC-6 (EVAL): standard-2 lacks d028_found lastUpdated-advance"
for id in deep-2 deep-3; do
  jq -e --arg id "$id" '.[] | select(.id == $id) | .d028_found | index("stats-empty-query-parity")' \
    "$cases" >/dev/null || fail "AC-6 (EVAL): $id lacks d028_found stats-empty-query-parity"
done
jq -e '.[] | select(.id == "standard-3") | .d028_found | index("checksum-first-record") | not' "$cases" >/dev/null \
  || fail "AC-6 (EVAL): standard-3 must record that D-028 missed checksum-first-record"

# --- AC-4 (EVAL): no-test-command case declares n/a and its prompt names no command -------
jq -e 'map(select(.id == "no-test-command")) | length == 1' "$cases" >/dev/null \
  || fail "AC-4 (EVAL): no-test-command case missing"
ntc_bundle="$dataset/$(jq -r '.[] | select(.id == "no-test-command") | .bundle' "$cases")"
ntc_prompt="$dataset/$(jq -r '.[] | select(.id == "no-test-command") | .prompt' "$cases")"
ntc_checkout="$(jq -r '.[] | select(.id == "no-test-command") | .checkout' "$cases")"
git clone -q -b "$ntc_checkout" "$ntc_bundle" "$tmp/ntc" 2>/dev/null || fail "AC-4 (EVAL): bundle does not clone"
conv="$(cat "$tmp/ntc/.claude/rules/lcd-conventions.md")"
for key in gate bail scoped-test; do
  grep -Eq "^${key}: n/a" <<<"$conv" || fail "AC-4 (EVAL): $key is not n/a in the no-test-command case"
done
if grep -q 'node --test' "$ntc_prompt"; then fail "AC-4 (EVAL): prompt names a test command"; fi

# --- Synthetic dataset + fake model for the runner tests ----------------------------------
# A one-commit project whose declared gate is `true`, bundled; the fake model binary performs
# real side effects in its cwd (the replay workspace) and emits a stream-json transcript.
syn="$tmp/syn"; mkdir -p "$syn/bundles" "$syn/prompts" "$tmp/proj/.claude/rules"
( cd "$tmp/proj" && git init -q -b main && git config user.email t@t && git config user.name t \
  && printf '<!-- lcd-conventions:v1 -->\nartifact-root: docs/lcd\ngate: true\n<!-- /lcd-conventions -->\n' \
       > .claude/rules/lcd-conventions.md && echo x > core.js && git add -A && git commit -qm init )
sha="$(git -C "$tmp/proj" rev-parse --short HEAD)"
git -C "$tmp/proj" bundle create "$syn/bundles/syn.bundle" main 2>/dev/null
printf 'Project root: {ROOT}. Refute the closeout.\n' > "$syn/prompts/syn.md"
printf '[{"id":"syn","bundle":"bundles/syn.bundle","refs":{"main":"%s"},"checkout":"main","prompt":"prompts/syn.md","known_defects":[],"d028_found":[]}]\n' \
  "$sha" > "$syn/cases.json"

fake="$tmp/fake-claude"
cat > "$fake" <<'FAKE'
#!/usr/bin/env bash
# Fake model CLI: records argv + the stdin prompt, performs FAKE_MODE side effects, emits stream-json.
[[ "${1:-}" == --version ]] && { echo "fake-claude 0.0"; exit 0; }
{ printf '%s\n' "$@"; cat; } > "${FAKE_ARGV:-/dev/null}"
emit_bash() { # id, command, output
  jq -cn --arg id "$1" --arg c "$2" '{type:"assistant",message:{id:("m"+$id),content:[{type:"tool_use",id:$id,name:"Bash",input:{command:$c}}]}}'
  jq -cn --arg id "$1" --arg o "$3" '{type:"user",message:{content:[{type:"tool_result",tool_use_id:$id,content:$o}]}}'
}
emit_bash t1 'true' 'suite ok'
emit_bash t2 'd=$(mktemp -d) && git clone -q . "$d/c" && cd "$d/c" && true' 'mutant survived'
emit_bash t3 'rm -rf /tmp/lcd-fixed-probe' ''
case "${FAKE_MODE:-clean}" in
  limit) jq -cn '{type:"result",is_error:true,result:"You have hit your 5-hour limit"}'; exit 1 ;;
  dirty-file) echo junk > stray.txt ;;
  dirty-ref)  git update-ref refs/heads/evil HEAD ;;
esac
jq -cn '{type:"result",result:"verdict: challenged\nfindings: ...",total_cost_usd:0.25,usage:{input_tokens:10,cache_read_input_tokens:1000,cache_creation_input_tokens:200,output_tokens:50}}'
FAKE
chmod +x "$fake"
run_replay() { # out-dir, extra args...
  local out="$1"; shift
  EVAL_CLAUDE_BIN="$fake" bash "$runner" run --dataset "$syn" --old-ref HEAD --new-ref HEAD \
    --reps 1 --arms new --out "$out" "$@" 2>&1
}
row_field() { # rows-file, column-name → value from the first data row
  awk -F'\t' -v c="$2" 'NR==1{for(i=1;i<=NF;i++) if($i==c) k=i; next} NR==2{print $k}' "$1"
}

# --- AC-1 (EVAL): runner counts executed suite runs from the transcript -------------------
out="$(EVAL_CLAUDE_BIN="$fake" bash "$runner" run --dataset "$syn" --old-ref HEAD --new-ref HEAD \
        --reps 3 --out "$tmp/dry" --dry-run 2>&1)"; code=$?
assert_exit 0 "$code" "AC-1 (EVAL): dry-run exits 0"
assert_contains "$out" 'DRY RUN' "AC-1 (EVAL): dry-run banner"
assert_contains "$out" 'dispatches: 6' "AC-1 (EVAL): plan counts 1 case x 2 arms x 3 reps"
assert_contains "$out" 'claude-fable-5-1' "AC-1 (EVAL): plan names the default model (D-028 tier)"
assert_contains "$out" 'enabledPlugins' "AC-1 (EVAL): plan shows plugin isolation"
assert_contains "$out" 'advisor' "AC-1 (EVAL): plan shows the disallowed user tool"
[[ ! -e "$tmp/dry" ]] || fail "AC-1 (EVAL): dry-run must not create the out dir"
out="$(FAKE_ARGV="$tmp/argv" run_replay "$tmp/r1")"; code=$?
assert_exit 0 "$code" "AC-1 (EVAL): run exits 0
$out"
rows="$tmp/r1/rows.tsv"
[[ -f "$rows" ]] || fail "AC-1 (EVAL): rows.tsv not written"
[[ "$(row_field "$rows" suite_runs)" == 2 ]] \
  || fail "AC-1 (EVAL): suite_runs should count both gate-command runs (got $(row_field "$rows" suite_runs))"
argv="$(cat "$tmp/argv")"
assert_contains "$argv" 'lcd:lcd-evaluator' "AC-1 (EVAL): dispatch runs the evaluator agent"
assert_contains "$argv" 'Project root: /' "AC-1 (EVAL): {ROOT} replaced with the workspace path"
assert_not_contains "$argv" '{ROOT}' "AC-1 (EVAL): no template left in the prompt"
[[ "$(row_field "$rows" verdict)" == challenged ]] || fail "AC-1 (EVAL): verdict parsed from result"

# --- AC-2 (EVAL): runner counts mutant runs in fresh temp copies -------------------------
[[ "$(row_field "$rows" mktemp_copies)" == 1 ]] \
  || fail "AC-2 (EVAL): mktemp_copies should be 1 (got $(row_field "$rows" mktemp_copies))"

# --- AC-3 (EVAL): runner flags a dispatch that changes the work tree or deletes a fixed path
[[ "$(row_field "$rows" tree_unchanged)" == yes ]] || fail "AC-3 (EVAL): clean dispatch must be tree_unchanged=yes"
[[ "$(row_field "$rows" fixed_path_deletes)" == 1 ]] || fail "AC-3 (EVAL): rm -rf of a literal path must count"
FAKE_MODE=dirty-file run_replay "$tmp/r2" >/dev/null
[[ "$(row_field "$tmp/r2/rows.tsv" tree_unchanged)" == no ]] || fail "AC-3 (EVAL): a stray file must flag the tree"
FAKE_MODE=dirty-ref run_replay "$tmp/r3" >/dev/null
[[ "$(row_field "$tmp/r3/rows.tsv" tree_unchanged)" == no ]] || fail "AC-3 (EVAL): a new ref must flag the tree"

# --- AC-5 (EVAL): runner writes the executed-command log per dispatch --------------------
log="$(ls "$tmp/r1"/syn/new-1.commands.txt 2>/dev/null)" || fail "AC-5 (EVAL): command log missing"
logc="$(cat "$log")"
assert_contains "$logc" '$ true' "AC-5 (EVAL): log lists the executed command"
assert_contains "$logc" 'mutant survived' "AC-5 (EVAL): log carries the command's output"
[[ "$(row_field "$rows" total_tokens)" == 1260 ]] || fail "AC-5 (EVAL): tokens summed from the result usage"
run_replay "$tmp/r1" --reps 2 >/dev/null 2>&1 && fail "AC-5 (EVAL): run must refuse an existing out dir"
sum="$(bash "$runner" summarize --out "$tmp/r1" 2>&1)"; code=$?
assert_exit 0 "$code" "AC-5 (EVAL): summarize exits 0"
assert_contains "$sum" 'new' "AC-5 (EVAL): summary row per arm"
assert_contains "$sum" '1260' "AC-5 (EVAL): summary reports mean tokens per arm"

# --- AC-6 (EVAL): runner refuses on a failed dispatch instead of recording it as a result ---
out="$(FAKE_MODE=limit run_replay "$tmp/r4")"; code=$?
[[ $code -ne 0 ]] || fail "AC-6 (EVAL): a failed dispatch (usage limit / is_error) must stop the run"
assert_contains "$out" 'dispatch failed' "AC-6 (EVAL): refusal names the failed dispatch"
[[ "$(row_field "$tmp/r4/rows.tsv" verdict)" == error ]] || fail "AC-6 (EVAL): failed dispatch row is marked error"

# --- AC-7: evaluator docs say it executes in throwaway copies and never edits the work tree
for f in agents/lcd-evaluator.md skills/triage/references/closeout.md rules/lcd.md README.md; do
  c="$(cat "$plugin_root/$f")"
  assert_contains "$c" 'never edits the work tree' "AC-7: $f states the work-tree guarantee"
done
assert_contains "$(cat "$plugin_root/agents/lcd-evaluator.md")" 'throwaway cop' "AC-7: agent names throwaway copies"
assert_not_contains "$(cat "$plugin_root/agents/lcd-evaluator.md")" 'You are read-only' "AC-7: agent no longer read-only"
assert_not_contains "$(cat "$plugin_root/skills/triage/references/closeout.md")" '(read-only, fresh context)' \
  "AC-7: closeout no longer calls the evaluator read-only"
assert_not_contains "$(grep 'lcd-evaluator' "$plugin_root/rules/lcd.md")" 'read-only closeout' \
  "AC-7: rules/lcd.md role text updated"

echo "test-eval-replay: all assertions passed"
