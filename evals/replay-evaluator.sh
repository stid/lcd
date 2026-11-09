#!/usr/bin/env bash
# replay-evaluator.sh — replay the lcd-evaluator agent over a frozen dataset of closeouts
# (work-item: evaluator-exec, harness D-034). Each case is a git bundle truncated at the commit
# the original evaluator saw, plus that dispatch's prompt; the runner replays it under two plugin
# refs (old vs new agent prompt) so the implementation under review is held constant.
#
# Usage:
#   evals/replay-evaluator.sh run --old-ref <ref> --new-ref <ref> --out <dir>
#       [--reps N] [--cases id,id] [--arms old,new] [--model id] [--dataset dir] [--dry-run]
#   evals/replay-evaluator.sh summarize --out <dir>
#
# Per dispatch it records one row in <out>/rows.tsv and, under <out>/<case>/:
#   <arm>-<rep>.jsonl (stream-json transcript), .commands.txt (every Bash command + output, for
#   checking executed claims), .report.md (the evaluator's final report), .stderr.
# Mechanical columns: tree_unchanged (git status incl. ignored, refs, stash, HEAD, worktrees,
# file contents and .git/config identical before/after), suite_runs (Bash commands containing
# the project's declared gate), mktemp_copies, fixed_path_deletes (rm -r of a literal path).
# Semantic grading (recall, precision) is done by a person/agent into evals/quality/.
#
# The model call uses --dangerously-skip-permissions — acceptable only because every case runs
# in a fresh mktemp clone outside <out> (so a dispatch cannot read other dispatches' results).
# Isolation is settings-only (D-025): installed plugins disabled by an object map, the arm's
# plugin added with --plugin-dir, the user-level `advisor` tool disallowed.
set -euo pipefail

plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
claude_bin="${EVAL_CLAUDE_BIN:-claude}"
refuse() { echo "refused: $1" >&2; exit 2; }
usage() { sed -n '6,9p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

cmd="${1:-}"; [[ $# -gt 0 ]] && shift
[[ "$cmd" == run || "$cmd" == summarize ]] || usage

old_ref="" new_ref="" out="" reps=3 only_cases="" arms="old,new" model="claude-fable-5-1"
dataset="$plugin_root/evals/evaluator-replay" dry_run=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --old-ref) old_ref="$2"; shift 2 ;;
    --new-ref) new_ref="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    --reps) reps="$2"; shift 2 ;;
    --cases) only_cases="$2"; shift 2 ;;
    --arms) arms="$2"; shift 2 ;;
    --model) model="$2"; shift 2 ;;
    --dataset) dataset="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    *) refuse "unknown argument: $1" ;;
  esac
done
[[ -n "$out" ]] || refuse "--out is required"

if [[ "$cmd" == summarize ]]; then
  [[ -f "$out/rows.tsv" ]] || refuse "no rows.tsv under $out"
  awk -F'\t' '
    NR == 1 { for (i = 1; i <= NF; i++) col[$i] = i; next }
    {
      k = $col["arm"]; ck = $col["case"] "\t" $col["arm"]
      if (!(k in n)) arms[++na] = k
      if (!(ck in cn)) cks[++nc] = ck
      n[k]++; tok[k] += $col["total_tokens"]; cost[k] += $col["cost_usd"]
      clean[k] += ($col["tree_unchanged"] == "yes"); suite[k] += $col["suite_runs"]
      mk[k] += $col["mktemp_copies"]; fixed[k] += $col["fixed_path_deletes"]
      chal[k] += ($col["verdict"] == "challenged")
      cn[ck]++; ctok[ck] += $col["total_tokens"]; cchal[ck] += ($col["verdict"] == "challenged")
      cmk[ck] += $col["mktemp_copies"]
    }
    END {
      print "arm\tn\tmean_tokens\tmean_cost\ttree_unchanged\tmean_suite_runs\tmean_mktemp_copies\tfixed_path_deletes\tchallenged"
      for (i = 1; i <= na; i++) { k = arms[i]
        printf "%s\t%d\t%.0f\t%.3f\t%d/%d\t%.1f\t%.1f\t%d\t%d/%d\n", k, n[k], tok[k]/n[k], cost[k]/n[k],
          clean[k], n[k], suite[k]/n[k], mk[k]/n[k], fixed[k], chal[k], n[k] }
      print ""
      print "case\tarm\tn\tmean_tokens\tmean_mktemp_copies\tchallenged"
      for (i = 1; i <= nc; i++) { k = cks[i]
        printf "%s\t%d\t%.0f\t%.1f\t%d/%d\n", k, cn[k], ctok[k]/cn[k], cmk[k]/cn[k], cchal[k], cn[k] }
    }' "$out/rows.tsv"
  exit 0
fi

# --- run: preflight (fail closed, naming the precondition) ---------------------------------
command -v jq >/dev/null 2>&1 || refuse "jq required"
command -v "$claude_bin" >/dev/null 2>&1 || refuse "model CLI not found: $claude_bin (set EVAL_CLAUDE_BIN)"
manifest="$dataset/cases.json"
[[ -f "$manifest" ]] || refuse "dataset manifest not found: $manifest"
jq -e 'type == "array"' "$manifest" >/dev/null 2>&1 || refuse "cannot parse $manifest"
[[ "$reps" =~ ^[1-9][0-9]*$ ]] || refuse "--reps must be a positive integer"
[[ ! -e "$out" ]] || refuse "out dir already exists: $out"

arm_list=""
for arm in ${arms//,/ }; do
  case "$arm" in
    old) ref="$old_ref" ;; new) ref="$new_ref" ;; *) refuse "unknown arm: $arm (old|new)" ;;
  esac
  [[ -n "$ref" ]] || refuse "--$arm-ref is required for arm $arm"
  sha="$(git -C "$plugin_root" rev-parse --verify --quiet "$ref^{commit}")" \
    || refuse "unknown git ref for arm $arm: $ref"
  arm_list="$arm_list $arm:$sha"
done

case_ids="$(jq -r '.[].id' "$manifest")"
if [[ -n "$only_cases" ]]; then
  for c in ${only_cases//,/ }; do grep -qx "$c" <<<"$case_ids" || refuse "unknown case: $c"; done
  case_ids="$(tr ',' '\n' <<<"$only_cases")"
fi
for c in $case_ids; do
  [[ -f "$dataset/$(jq -r --arg c "$c" '.[] | select(.id == $c) | .bundle' "$manifest")" ]] \
    || refuse "bundle missing for case $c"
  [[ -f "$dataset/$(jq -r --arg c "$c" '.[] | select(.id == $c) | .prompt' "$manifest")" ]] \
    || refuse "prompt missing for case $c"
done

# Plugin-disable map (same contract as run-eval.sh, 0.17.1): an object map with an explicit
# false per user-enabled plugin; --plugin-dir then adds the arm's plugin.
user_settings="${HOME}/.claude/settings.json"
if [[ -f "$user_settings" ]]; then
  disable_map="$(jq -c '{enabledPlugins: ((.enabledPlugins // {}) | with_entries(.value = false))}' \
      "$user_settings" 2>/dev/null)" || refuse "cannot parse $user_settings to build the plugin-disable map"
  [[ -n "$disable_map" ]] || refuse "cannot parse $user_settings to build the plugin-disable map"
else
  disable_map='{"enabledPlugins":{}}'
fi

n_cases="$(grep -c . <<<"$case_ids")"; n_arms="$(wc -w <<<"$arm_list" | tr -d ' ')"
dispatches=$((n_cases * n_arms * reps))
plan() {
  echo "  arms:$arm_list"
  echo "  cases: $(tr '\n' ' ' <<<"$case_ids")"
  echo "  reps: $reps · model: $model · dispatches: $dispatches"
  echo "  dataset: $dataset"
  echo "  isolation: --settings $disable_map · --disallowedTools advisor · CLAUDE_CONFIG_DIR unset"
}
if [[ $dry_run -eq 1 ]]; then echo "DRY RUN — nothing executed"; plan; exit 0; fi

mkdir -p "$out"
{ echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"; plan
  echo "  cli: $("$claude_bin" --version </dev/null 2>/dev/null | head -1 || echo unknown)"; } > "$out/meta.txt"
for a in $arm_list; do
  mkdir -p "$out/plugin-${a%%:*}"
  git -C "$plugin_root" archive "${a#*:}" | tar -x -C "$out/plugin-${a%%:*}"
done

snapshot() { # one checksum over everything a dispatch must not change
  local w="$1"
  {
    git -C "$w" status --porcelain --ignored --untracked-files=all
    git -C "$w" for-each-ref
    git -C "$w" stash list
    git -C "$w" rev-parse HEAD
    git -C "$w" symbolic-ref -q HEAD || true
    git -C "$w" worktree list --porcelain
    cat "$w/.git/config"
    (cd "$w" && find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done)
  } | cksum
}

printf 'case\tarm\trep\tverdict\ttree_unchanged\tsuite_runs\tmktemp_copies\tfixed_path_deletes\tinput_tokens\tcache_read\tcache_create\toutput_tokens\ttotal_tokens\tcost_usd\texit\ttranscript\n' \
  > "$out/rows.tsv"
root_tok='{ROOT}'
for c in $case_ids; do
  mkdir -p "$out/$c"
  bundle="$dataset/$(jq -r --arg c "$c" '.[] | select(.id == $c) | .bundle' "$manifest")"
  tmpl="$(cat "$dataset/$(jq -r --arg c "$c" '.[] | select(.id == $c) | .prompt' "$manifest")")"
  checkout="$(jq -r --arg c "$c" '.[] | select(.id == $c) | .checkout' "$manifest")"
  refs="$(jq -r --arg c "$c" '.[] | select(.id == $c) | .refs | to_entries[] | "\(.key)=\(.value)"' "$manifest")"
  for rep in $(seq 1 "$reps"); do
    for a in $arm_list; do
      arm="${a%%:*}"; base="$out/$c/$arm-$rep"
      ws_parent="$(mktemp -d "${TMPDIR:-/tmp}/lcd-replay-XXXXXX")"; ws="$ws_parent/w"
      git clone -q "$bundle" "$ws" 2>/dev/null || refuse "cannot clone bundle for case $c"
      git -C "$ws" checkout -q --detach
      for r in $refs; do git -C "$ws" branch -q -f "${r%%=*}" "${r#*=}"; done
      git -C "$ws" checkout -q "$checkout"
      git -C "$ws" remote remove origin
      ws_real="$(cd "$ws" && pwd -P)"
      gate="$(sed -n 's/^gate:[[:space:]]*//p' "$ws/.claude/rules/lcd-conventions.md" 2>/dev/null | head -1)"
      [[ "$gate" == n/a* ]] && gate=""
      before="$(snapshot "$ws")"
      code=0
      ( unset CLAUDE_CONFIG_DIR; cd "$ws" && IS_SANDBOX=1 "$claude_bin" -p --agent lcd:lcd-evaluator \
          --plugin-dir "$out/plugin-$arm" --settings "$disable_map" --model "$model" \
          --output-format stream-json --verbose --dangerously-skip-permissions \
          --disallowedTools advisor <<<"${tmpl//$root_tok/$ws_real}" ) > "$base.jsonl" 2> "$base.stderr" || code=$?
      after="$(snapshot "$ws")"
      unchanged=no; [[ "$before" == "$after" ]] && unchanged=yes
      /bin/rm -rf "$ws_parent"

      metrics="$(jq -rs --arg g "$gate" '
        [ .[] | select(.type == "assistant") | .message.content[]?
          | select(.type == "tool_use" and .name == "Bash") | .input.command ] as $c
        | (map(select(.type == "result")) | last // {}) as $r
        | ($r.usage // {}) as $u
        | [ ($c | map(select($g != "" and contains($g))) | length),
            ($c | map(select(test("mktemp"))) | length),
            ($c | map([scan("rm\\s+-[A-Za-z]*[rR][A-Za-z]*\\s+(?:-\\S+\\s+)*(/[^\\s$;&|\"'"'"']+)")] | length) | add // 0),
            ($u.input_tokens // 0), ($u.cache_read_input_tokens // 0),
            ($u.cache_creation_input_tokens // 0), ($u.output_tokens // 0),
            (($u.input_tokens // 0) + ($u.cache_read_input_tokens // 0)
              + ($u.cache_creation_input_tokens // 0) + ($u.output_tokens // 0)),
            ($r.total_cost_usd // 0),
            (($r.result // "") | ascii_downcase | [scan("challenged|stands")] | first // "unknown") ]
        | @tsv' "$base.jsonl" 2>/dev/null)" || metrics="$(printf '0\t0\t0\t0\t0\t0\t0\t0\t0\tunknown')"
      jq -rs '
        (map(select(.type == "user") | .message.content[]? | select(.type == "tool_result")
             | {key: .tool_use_id, value: (if (.content | type) == "string" then .content
                 else ([.content[]? | .text? // empty] | join("\n")) end)}) | from_entries) as $res
        | .[] | select(.type == "assistant") | .message.content[]?
        | select(.type == "tool_use" and .name == "Bash")
        | "$ \(.input.command)\n\(($res[.id] // "") | .[0:4000])\n"' "$base.jsonl" > "$base.commands.txt" 2>/dev/null || true
      jq -rs 'map(select(.type == "result")) | last | .result // ""' "$base.jsonl" > "$base.report.md" 2>/dev/null || true

      IFS=$'\t' read -r suite mk fixed tin tcr tcc tout ttot cost verdict <<<"$metrics"
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$c" "$arm" "$rep" \
        "$verdict" "$unchanged" "$suite" "$mk" "$fixed" "$tin" "$tcr" "$tcc" "$tout" "$ttot" "$cost" \
        "$code" "$base.jsonl" >> "$out/rows.tsv"
      echo "$c $arm rep $rep: $verdict · tree_unchanged=$unchanged · tokens=$ttot · exit=$code"
    done
  done
done
echo "rows: $out/rows.tsv"
