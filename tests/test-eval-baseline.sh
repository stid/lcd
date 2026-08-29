#!/usr/bin/env bash
# Tests for the eval baseline arm (work-item: t1-baseline-eval, harness D-025).
# Covers evals/run-eval.sh --baseline, evals/grade.sh --baseline, the frozen baseline
# prompt's feature-paragraph parity, and cross-arm row-shape comparability.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
runner="$plugin_root/evals/run-eval.sh"
grader="$plugin_root/evals/grade.sh"
base_prompt="$plugin_root/evals/feature-prompt-baseline.md"

init_tmpdir

# A minimal fake LCD-onboarded fixture (same shape the runner tests use).
fixture="$tmp/fixture"
mkdir -p "$fixture/.claude/rules" "$fixture/docs/lcd" "$fixture/tests"
echo '{"name":"fake-fixture","scripts":{"test":"node --test tests/"}}' > "$fixture/package.json"
printf '<!-- lcd-conventions:v1 -->\nartifact-root: docs/lcd\n<!-- /lcd-conventions -->\n' \
  > "$fixture/.claude/rules/lcd-conventions.md"
echo '# MAP' > "$fixture/docs/lcd/MAP.md"

# --- AC-1 (CLI): baseline dry-run resolves the identical run plan, methodology absent ----
out="$(EVAL_CLAUDE_BIN=bash bash "$runner" --arm none --baseline --fixture "$fixture" \
        --results "$tmp/r1.md" --workspace "$tmp/ws-dry" --dry-run 2>&1)"; code=$?
assert_exit 0 "$code" "AC-1 (CLI): baseline dry-run exits 0 without --plugin-dir"
assert_contains "$out" 'DRY RUN' "AC-1 (CLI): dry-run banner printed"
assert_contains "$out" 'arm: none' "AC-1 (CLI): plan names the baseline arm"
assert_contains "$out" "$fixture" "AC-1 (CLI): plan names the same fixture"
assert_contains "$out" 'stats-surfaces' "AC-1 (CLI): plan names the same scripted slug"
assert_contains "$out" 'plugin: none (baseline)' "AC-1 (CLI): plan states the methodology is absent"
assert_contains "$out" 'feature-prompt-baseline.md' "AC-1 (CLI): plan names the baseline prompt"
[[ ! -e "$tmp/ws-dry" ]] || fail "AC-1 (CLI): dry-run must not materialize a workspace"

# --- AC-1 (CLI): isolation contract is symmetric — both arms show it in the plan --------
assert_contains "$out" 'CLAUDE_CONFIG_DIR' "AC-1 (CLI): baseline plan shows config isolation"
assert_contains "$out" 'enabledPlugins' "AC-1 (CLI): baseline plan shows plugin isolation"
out="$(EVAL_CLAUDE_BIN=bash bash "$runner" --arm A --fixture "$fixture" \
        --plugin-dir "$plugin_root" --results "$tmp/r1.md" --workspace "$tmp/ws-dry2" --dry-run 2>&1)"; code=$?
assert_exit 0 "$code" "AC-1 (CLI): plugin-arm dry-run still exits 0"
assert_contains "$out" 'CLAUDE_CONFIG_DIR' "AC-1 (CLI): plugin-arm plan shows the same config isolation"
assert_contains "$out" 'enabledPlugins' "AC-1 (CLI): plugin-arm plan shows the same plugin isolation"

# --- AC-1 (CLI): frozen prompts share a byte-identical feature paragraph ----------------
[[ -f "$base_prompt" ]] || fail "AC-1 (CLI): evals/feature-prompt-baseline.md exists"
para_lcd="$(sed -n '/^Add a `stats` operation/,/^$/p' "$plugin_root/evals/feature-prompt.md")"
para_base="$(sed -n '/^Add a `stats` operation/,/^$/p' "$base_prompt")"
[[ -n "$para_lcd" ]] || fail "AC-1 (CLI): LCD prompt feature paragraph extracted"
[[ "$para_lcd" == "$para_base" ]] || fail "AC-1 (CLI): feature paragraph byte-identical across arms"
assert_not_contains "$para_base" 'LCD' "AC-1 (CLI): feature paragraph itself is methodology-free"
assert_contains "$(cat "$base_prompt")" 'EVAL-DONE' "AC-1 (CLI): baseline prompt names the EVAL-DONE finish line"

# --- AC-2 (CLI): --baseline with --plugin-dir is a contradiction — refused --------------
out="$(EVAL_CLAUDE_BIN=bash bash "$runner" --arm none --baseline --fixture "$fixture" \
        --plugin-dir "$plugin_root" --dry-run 2>&1)"; code=$?
assert_exit 2 "$code" "AC-2 (CLI): --baseline with --plugin-dir refused"
assert_contains "$out" 'refused' "AC-2 (CLI): refusal is explicit"
assert_contains "$out" 'baseline' "AC-2 (CLI): refusal names the contradiction"

# --- AC-2 (CLI): baseline workspace is stripped of methodology artifacts ----------------
results="$tmp/results.md"
ws="$tmp/ws-strip"
out="$(EVAL_CLAUDE_BIN=bash EVAL_MAX_LEGS=0 bash "$runner" --arm none --baseline \
        --fixture "$fixture" --results "$results" --workspace "$ws" 2>&1)"; code=$?
assert_exit 0 "$code" "AC-2 (CLI): zero-leg baseline run completes"
[[ -d "$ws" ]] || fail "AC-2 (CLI): baseline workspace materialized"
[[ ! -e "$ws/.claude" ]] || fail "AC-2 (CLI): workspace has no .claude/ (onboarding stripped)"
[[ ! -e "$ws/docs" ]] || fail "AC-2 (CLI): workspace has no docs/ (methodology artifacts stripped)"
[[ -f "$ws/package.json" ]] || fail "AC-2 (CLI): project files survive the strip"

# --- AC-2 (CLI): residue that cannot be stripped fails closed ---------------------------
fixture_ro="$tmp/fixture-ro"
cp -R "$fixture" "$fixture_ro"
chmod a-w "$fixture_ro/docs"    # cp -R preserves the mode; files under docs/ can't be unlinked
out="$(EVAL_CLAUDE_BIN=bash EVAL_MAX_LEGS=0 bash "$runner" --arm none --baseline \
        --fixture "$fixture_ro" --results "$tmp/r2.md" --workspace "$tmp/ws-residue" 2>&1)"; code=$?
chmod -R u+w "$fixture_ro" "$tmp/ws-residue" 2>/dev/null
assert_exit 2 "$code" "AC-2 (CLI): unstripped residue refused"
assert_contains "$out" 'refused' "AC-2 (CLI): residue refusal is explicit"

# --- AC-3 (EVAL): grader emits the standard row shape for a bare baseline workspace -----
bare="$tmp/bare-ws"
mkdir -p "$bare/tests"
echo '{"name":"bare","scripts":{"test":"node --test tests/"}}' > "$bare/package.json"
printf 'const t=require("node:test");t.test("ok",()=>{});\n' > "$bare/tests/ok.test.js"
git -C "$bare" init -q -b main >/dev/null
git -C "$bare" add -A
git -C "$bare" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -qm base
git -C "$bare" tag eval-baseline
printf 'x\n' > "$bare/done.txt"
git -C "$bare" add -A
git -C "$bare" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -qm work
row="$(bash "$grader" --baseline "$bare" stats-surfaces none 2>&1)"; code=$?
assert_exit 0 "$code" "AC-3 (EVAL): baseline grading exits 0"
assert_contains "$row" 'audit: n/a (n/a non-OK)' "AC-3 (EVAL): audit column short-circuits to n/a"
assert_contains "$row" 'suite: green' "AC-3 (EVAL): suite column still graded"
assert_contains "$row" 'commits: 1' "AC-3 (EVAL): commit count still graded from the eval-baseline tag"
assert_contains "$row" 'interventions: n/a' "AC-3 (EVAL): row ends with the standard columns"

# --- AC-3 (EVAL): fail-closed both ways — flag and workspace type must agree ------------
out="$(bash "$grader" --baseline "$fixture" stats-surfaces none 2>&1)"; code=$?
assert_exit 2 "$code" "AC-3 (EVAL): --baseline on a methodology workspace refused"
assert_contains "$out" 'docs/lcd' "AC-3 (EVAL): refusal names the residue"
out="$(bash "$grader" "$bare" stats-surfaces none 2>&1)"; code=$?
assert_exit 2 "$code" "AC-3 (EVAL): bare workspace without --baseline still refused (existing contract preserved)"

# --- AC-4 (EVAL): both arms append same-shape rows to one results file ------------------
out="$(EVAL_CLAUDE_BIN=bash EVAL_MAX_LEGS=0 bash "$runner" --arm A --fixture "$fixture" \
        --plugin-dir "$plugin_root" --results "$results" --workspace "$tmp/ws-lcd" 2>&1)"; code=$?
assert_exit 0 "$code" "AC-4 (EVAL): zero-leg plugin-arm run appends alongside the baseline row"
rows="$(grep -c ' · audit: ' "$results" || true)"
[[ "$rows" -eq 2 ]] || fail "AC-4 (EVAL): results file holds one row per arm (got $rows)"
cols_a="$(tail -1 "$results" | awk -F' · ' '{print NF}')"
cols_b="$(grep ' · none · ' "$results" | head -1 | awk -F' · ' '{print NF}')"
[[ -n "$cols_b" ]] || fail "AC-4 (EVAL): baseline row present and labelled with its arm"
[[ "$cols_a" -eq "$cols_b" ]] || fail "AC-4 (EVAL): rows are column-identical across arms ($cols_a vs $cols_b)"

# --- AC-2 (CLI): the model call's REAL argv is isolated (evaluator finding, 0.17.1) -----
# An argv-recording stub stands in for the model CLI: these tests assert what the leg loop
# actually executes, not what the runner prints. Fake HOME provides a user settings.json
# with enabled plugins; the runner must pass --settings with an OBJECT map disabling each.
stub="$tmp/claude-stub.sh"
cat > "$stub" << 'EOS'
#!/usr/bin/env bash
printf '%s\n' "$@" > "${ARGV_OUT:?}"
echo '{}'
EOS
chmod +x "$stub"
fakehome="$tmp/fakehome"
mkdir -p "$fakehome/.claude"
echo '{"enabledPlugins":{"lcd@lcd":true,"other@mkt":true}}' > "$fakehome/.claude/settings.json"

extract_settings() {  # print the value following --settings in the recorded argv
  awk 'found {print; exit} $0=="--settings" {found=1}' "$1"
}

export ARGV_OUT="$tmp/argv-none.txt"
out="$(HOME="$fakehome" EVAL_CLAUDE_BIN="$stub" EVAL_MAX_LEGS=1 bash "$runner" --arm none --baseline \
        --fixture "$fixture" --results "$tmp/r-argv.md" --workspace "$tmp/ws-argv-none" 2>&1)"; code=$?
assert_exit 0 "$code" "AC-2 (CLI): one-leg baseline run with argv stub completes"
[[ -f "$ARGV_OUT" ]] || fail "AC-2 (CLI): baseline leg actually invoked the model CLI"
argv="$(cat "$ARGV_OUT")"
assert_not_contains "$argv" '--plugin-dir' "AC-2 (CLI): baseline model call carries no --plugin-dir"
settings_json="$(extract_settings "$ARGV_OUT")"
[[ -n "$settings_json" ]] || fail "AC-2 (CLI): baseline model call passes --settings"
echo "$settings_json" | jq -e '.enabledPlugins | type == "object"' >/dev/null \
  || fail "AC-2 (CLI): enabledPlugins is an object map (schema-valid), got: $settings_json"
echo "$settings_json" | jq -e '.enabledPlugins["lcd@lcd"] == false and .enabledPlugins["other@mkt"] == false' >/dev/null \
  || fail "AC-2 (CLI): every user-enabled plugin explicitly disabled, got: $settings_json"

export ARGV_OUT="$tmp/argv-lcd.txt"
out="$(HOME="$fakehome" EVAL_CLAUDE_BIN="$stub" EVAL_MAX_LEGS=1 bash "$runner" --arm A \
        --fixture "$fixture" --plugin-dir "$plugin_root" --results "$tmp/r-argv.md" \
        --workspace "$tmp/ws-argv-lcd" 2>&1)"; code=$?
assert_exit 0 "$code" "AC-2 (CLI): one-leg plugin-arm run with argv stub completes"
argv="$(cat "$ARGV_OUT")"
assert_contains "$argv" '--plugin-dir' "AC-2 (CLI): plugin-arm model call carries --plugin-dir"
settings_json="$(extract_settings "$ARGV_OUT")"
echo "$settings_json" | jq -e '.enabledPlugins["lcd@lcd"] == false' >/dev/null \
  || fail "AC-2 (CLI): plugin arm disables user-level plugins identically, got: $settings_json"
unset ARGV_OUT

# --- AC-2 (CLI): unparseable user settings fail closed ----------------------------------
badhome="$tmp/badhome"
mkdir -p "$badhome/.claude"
echo 'not json {' > "$badhome/.claude/settings.json"
out="$(HOME="$badhome" EVAL_CLAUDE_BIN=bash EVAL_MAX_LEGS=0 bash "$runner" --arm none --baseline \
        --fixture "$fixture" --results "$tmp/r-bad.md" --workspace "$tmp/ws-bad" 2>&1)"; code=$?
assert_exit 2 "$code" "AC-2 (CLI): unparseable user settings.json refused (no silent inert isolation)"
assert_contains "$out" 'settings' "AC-2 (CLI): refusal names the settings file"

exit 0
