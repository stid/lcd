#!/usr/bin/env bash
# Tests for evals/run-eval.sh — the prompt-eval benchmark runner (work-item: eval-harness).
# The runner FAILS CLOSED (it's an instrument, unlike the plugin's fail-open hooks).
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
runner="$plugin_root/evals/run-eval.sh"

[[ -f "$runner" ]] || fail "evals/run-eval.sh does not exist"

init_tmpdir

# A minimal fake fixture satisfying the runner's preflight (the real fixture is
# integration-tested separately; runner tests stay independent of it).
fixture="$tmp/fixture"
mkdir -p "$fixture/.claude/rules" "$fixture/docs/lcd" "$fixture/tests"
echo '{"name":"fake-fixture","scripts":{"test":"node --test tests/"}}' > "$fixture/package.json"
printf '<!-- lcd-conventions:v1 -->\nartifact-root: docs/lcd\n<!-- /lcd-conventions -->\n' \
  > "$fixture/.claude/rules/lcd-conventions.md"
echo '# MAP' > "$fixture/docs/lcd/MAP.md"

plugin="$plugin_root"
results="$tmp/results.md"

# --- AC-1 (CLI): dry-run prints the resolved plan and exits 0, no model call ------
ws="$tmp/ws-should-not-exist"
out="$(EVAL_CLAUDE_BIN=bash bash "$runner" --arm A --fixture "$fixture" \
        --plugin-dir "$plugin" --results "$results" --workspace "$ws" --dry-run 2>&1)"; code=$?
assert_exit 0 "$code" "AC-1 (CLI): dry-run exits 0"
assert_contains "$out" 'DRY RUN' "AC-1 (CLI): dry-run banner printed"
assert_contains "$out" '--model claude-fable-5-1 ' "AC-1 (CLI): default model is the current tier (D-015: rows stamp it)"
assert_contains "$out" "$fixture" "AC-1 (CLI): plan names the fixture"
assert_contains "$out" 'arm: A' "AC-1 (CLI): plan names the arm"
assert_contains "$out" 'stats-surfaces' "AC-1 (CLI): plan names the scripted slug"
[[ ! -e "$ws" ]] || fail "AC-1 (CLI): dry-run must not materialize a workspace"
[[ ! -e "$results" ]] || fail "AC-1 (CLI): dry-run must not touch the results file"

# --- AC-1 (CLI): the appended row records the model id ----------------------------
# EVAL_MAX_LEGS=0 skips the model call entirely; the run still materializes, grades
# (INCOMPLETE is a valid row) and appends — enough to exercise the append path.
results_model="$tmp/results-model.md"
out="$(EVAL_CLAUDE_BIN=bash EVAL_CLAUDE_MODEL=test-model-x EVAL_MAX_LEGS=0 \
        bash "$runner" --arm A --fixture "$fixture" --plugin-dir "$plugin" \
        --results "$results_model" --workspace "$tmp/ws-model" 2>&1)"; code=$?
assert_exit 0 "$code" "AC-1 (CLI): zero-leg run grades and appends"
[[ -f "$results_model" ]] || fail "AC-1 (CLI): results file created"
row="$(tail -1 "$results_model")"
assert_contains "$row" 'model: test-model-x' "AC-1 (CLI): appended row records the model id"

# --- AC-4 (none): preconditions fail closed, naming the failure -------------------
out="$(EVAL_CLAUDE_BIN=bash bash "$runner" --arm A --fixture "$tmp/no-such-fixture" \
        --plugin-dir "$plugin" --dry-run 2>&1)"; code=$?
assert_exit 2 "$code" "AC-4: missing fixture refused"
assert_contains "$out" 'fixture' "AC-4: refusal names the fixture precondition"

out="$(EVAL_CLAUDE_BIN=bash bash "$runner" --arm A --fixture "$fixture" \
        --plugin-dir "$tmp/no-such-plugin" --dry-run 2>&1)"; code=$?
assert_exit 2 "$code" "AC-4: missing plugin variant refused"
assert_contains "$out" 'plugin' "AC-4: refusal names the plugin precondition"

out="$(EVAL_CLAUDE_BIN=definitely-no-such-cli-xyz bash "$runner" --arm A \
        --fixture "$fixture" --plugin-dir "$plugin" --workspace "$tmp/ws2" 2>&1)"; code=$?
assert_exit 2 "$code" "AC-4: missing model CLI refused (real run)"
assert_contains "$out" 'model CLI' "AC-4: refusal names the model CLI"
[[ ! -e "$tmp/ws2" ]] || fail "AC-4: refused run must not materialize a workspace"

# --- AC-6 (EVAL) — triage-routed arm (lean-loop): standard prompt, EVAL-DONE finish line
out="$(EVAL_CLAUDE_BIN=bash bash "$runner" --arm standard --triage-routed \
        --fixture "$fixture" --plugin-dir "$plugin" --results "$results" \
        --workspace "$tmp/ws-tr" --dry-run 2>&1)"; code=$?
assert_exit 0 "$code" "triage-routed dry-run exits 0"
assert_contains "$out" 'feature-prompt-standard.md' "AC-6 (EVAL): triage-routed selects the standard prompt"

out="$(EVAL_CLAUDE_BIN=bash bash "$runner" --arm x --triage-routed --baseline \
        --fixture "$fixture" --dry-run 2>&1)"; code=$?
assert_exit 2 "$code" "triage-routed contradicts baseline"

# --- no arm → usage --------------------------------------------------------------
out="$(bash "$runner" 2>&1)"; code=$?
assert_exit 2 "$code" "missing --arm rejected"
assert_contains "$out" 'usage:' "usage printed"

exit 0
