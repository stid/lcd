#!/usr/bin/env bash
# Tests for bin/lcd-staleness-check.sh — the Stop-hook resume-anchor guard.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

init_tmpdir
proj="$tmp/proj"
mkdir -p "$proj/.claude/rules" "$proj/docs/lcd/work/export-csv"
git -C "$proj" init -q -b feat/export-csv
git -C "$proj" -c user.email=t@t -c user.name=t -c commit.gpgsign=false \
  commit -q --allow-empty -m "work"
today="$(date +%F)"

cat > "$proj/.claude/rules/lcd-conventions.md" <<'EOF'
artifact-root: docs/lcd
EOF

write_journal() {  # $1 = Updated date, $2 = step state (" " or "x")
  cat > "$proj/docs/lcd/work/export-csv/JOURNAL.md" <<EOF
<!-- lcd-resume:v1 -->
## NOW
- **Lane:** Standard
- **Next action:** implement the writer
- **Branch:** feat/export-csv  ·  **Updated:** $1 14:00

## STEPS
- [$2] S1 — implement writer
<!-- /lcd-resume -->
EOF
}

run_hook() {
  CLAUDE_PROJECT_DIR="$proj" bash "$PLUGIN_BIN/lcd-staleness-check.sh" \
    <<< "{\"hook_event_name\":\"Stop\",\"stop_hook_active\":${1:-false}}" 2>&1
}

# --- stale journal (Updated < last commit) blocks the stop ---------------------
write_journal "2020-01-01" " "
out="$(run_hook)"; code=$?
assert_exit 2 "$code" "stale anchor blocks stop"
assert_contains "$out" "export-csv" "names the stale work-item"
assert_contains "$out" "Updated 2020-01-01" "names the stale date"

# --- loop guard: stop_hook_active → allow ---------------------------------------
out="$(run_hook true)"; code=$?
assert_exit 0 "$code" "stop_hook_active passes through"

# --- same-day journal → allow (no nagging mid-flow) ------------------------------
write_journal "$today" " "
out="$(run_hook)"; code=$?
assert_exit 0 "$code" "same-day anchor allows stop"

# --- done work-item → inactive → allow --------------------------------------------
write_journal "2020-01-01" "x"
out="$(run_hook)"; code=$?
assert_exit 0 "$code" "done work-item never blocks"

# --- not onboarded → allow ---------------------------------------------------------
rm "$proj/.claude/rules/lcd-conventions.md"
write_journal "2020-01-01" " "
out="$(run_hook)"; code=$?
assert_exit 0 "$code" "un-onboarded project never blocks"

exit 0
