#!/usr/bin/env bash
# Tests for bin/lcd-session-context.sh — the SessionStart context hook.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

init_tmpdir
proj="$tmp/proj"
mkdir -p "$proj/.claude/rules" "$proj/docs/lcd/work/export-csv"
git -C "$proj" init -q -b feat/export-csv

run_hook() {
  CLAUDE_PROJECT_DIR="$proj" bash "$PLUGIN_BIN/lcd-session-context.sh" <<< '{"hook_event_name":"SessionStart","source":"startup"}'
}

# --- not onboarded → silent ----------------------------------------------------
out="$(run_hook)"; code=$?
assert_exit 0 "$code" "un-onboarded exits 0"
[[ -z "$out" ]] || fail "un-onboarded project must emit nothing, got: $out"

# --- onboarded, no active work-item ---------------------------------------------
cat > "$proj/.claude/rules/lcd-conventions.md" <<'EOF'
<!-- lcd-conventions:v1 -->
artifact-root: docs/lcd
<!-- /lcd-conventions -->
EOF
out="$(run_hook)"; code=$?
assert_exit 0 "$code" "onboarded exits 0"
assert_contains "$out" '"hookEventName":"SessionStart"' "emits SessionStart JSON"
assert_contains "$out" 'docs/lcd/MAP.md' "context names the MAP"
assert_contains "$out" 'No work-item is active' "no-active case stated"

# --- active work-item on this branch is listed with lane + next action ----------
cat > "$proj/docs/lcd/work/export-csv/JOURNAL.md" <<'EOF'
<!-- lcd-resume:v1 -->
## NOW
- **Lane:** Standard
- **Goal:** CSV export
- **Next action:** implement the writer
- **Branch:** feat/export-csv  ·  **Updated:** 2026-06-10

## STEPS
- [ ] S2 — implement writer  ← next

## EDIT BOUNDARY (paths this work may touch)
- `src/export/`
<!-- /lcd-resume -->
EOF
out="$(run_hook)"
assert_contains "$out" 'export-csv [Standard' "active item listed with lane"
assert_contains "$out" 'implement the writer' "next action surfaced"
assert_contains "$out" '/lcd:resume export-csv' "resume command included"
assert_not_contains "$out" 'COMPACTED' "startup source carries no compaction note"
assert_not_contains "$out" 'edit boundary:' "startup source carries no boundary"

# --- post-compaction restart (source=compact) carries the resume spine -----------
run_compact() {
  CLAUDE_PROJECT_DIR="$proj" bash "$PLUGIN_BIN/lcd-session-context.sh" <<< '{"hook_event_name":"SessionStart","source":"compact"}'
}
out="$(run_compact)"; code=$?
assert_exit 0 "$code" "compact source exits 0"
assert_contains "$out" '"hookEventName":"SessionStart"' "compact emits SessionStart JSON"
assert_contains "$out" 'COMPACTED' "compaction note present"
assert_contains "$out" 'trust the JOURNAL' "ground-truth note present"
assert_contains "$out" 'edit boundary: src/export/' "EDIT BOUNDARY injected post-compaction"
assert_contains "$out" '/lcd:resume export-csv' "resume command still included"

# --- compact on an un-onboarded project stays silent (fail open) -----------------
proj2="$tmp/proj2"
mkdir -p "$proj2"
git -C "$proj2" init -q
out="$(CLAUDE_PROJECT_DIR="$proj2" bash "$PLUGIN_BIN/lcd-session-context.sh" <<< '{"hook_event_name":"SessionStart","source":"compact"}')"; code=$?
assert_exit 0 "$code" "un-onboarded compact exits 0"
[[ -z "$out" ]] || fail "un-onboarded compact must emit nothing, got: $out"

exit 0
