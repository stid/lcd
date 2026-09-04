#!/usr/bin/env bash
# Tests for bin/lcd-boundary-check.sh — the PreToolUse edit-boundary hook.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

init_tmpdir
proj="$tmp/proj"
mkdir -p "$proj/.claude/rules" "$proj/docs/lcd/work/export-csv" "$proj/src/export" "$proj/src/other"
git -C "$proj" init -q -b feat/export-csv

cat > "$proj/.claude/rules/lcd-conventions.md" <<'EOF'
<!-- lcd-conventions:v1 -->
artifact-root: docs/lcd
<!-- /lcd-conventions -->
EOF

cat > "$proj/docs/lcd/work/export-csv/JOURNAL.md" <<'EOF'
<!-- lcd-resume:v1 -->
## NOW
- **Lane:** Standard
- **Goal:** CSV export
- **Next action:** implement the writer
- **Branch:** feat/export-csv  ·  **Updated:** 2026-06-10

## STEPS
- [x] S1 — failing test
- [ ] S2 — implement writer  ← next

## EDIT BOUNDARY (paths this work may touch)
- `src/export/`
- `tests/export.test.ts`
- `docs/notes.md`, `README.md`
- `LICENSE` (kept for reference)
- `docs/a.md` · `docs/b.md` · `CHANGELOG.md`
- `docs/c.md`; `docs/d.md`
- `{src,lib}/shared/**`
<!-- /lcd-resume -->
EOF

# run <file_path> → captures stdout + exit code
run_hook() {
  CLAUDE_PROJECT_DIR="$proj" bash "$PLUGIN_BIN/lcd-boundary-check.sh" <<EOF
{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"$1"}}
EOF
}

# --- in-boundary edits are allowed (no output) -------------------------------
out="$(run_hook "$proj/src/export/writer.ts")"; code=$?
assert_exit 0 "$code" "in-boundary dir edit allowed"
[[ -z "$out" ]] || fail "in-boundary edit should produce no output, got: $out"

out="$(run_hook "$proj/tests/export.test.ts")"; code=$?
[[ -z "$out" ]] || fail "exact boundary file should be allowed, got: $out"

# --- a bullet listing several paths covers each of them ----------------------
# Authors write `- \`a.md\`, \`b.md\``; matching the bullet as one string denied both.
out="$(run_hook "$proj/docs/notes.md")"
[[ -z "$out" ]] || fail "first path of a comma-separated bullet should be allowed, got: $out"
out="$(run_hook "$proj/README.md")"
[[ -z "$out" ]] || fail "second path of a comma-separated bullet should be allowed, got: $out"

# --- `·` and `;` separated bullets are split like commas (stid/lcd#17) ---------
# Authors write `- \`a.md\` · \`b.md\`` too; matched whole, every path it lists is denied.
for f in docs/a.md docs/b.md CHANGELOG.md docs/c.md docs/d.md; do
  out="$(run_hook "$proj/$f")"
  [[ -z "$out" ]] || fail "path $f of a ·/;-separated bullet should be allowed, got: $out"
done

# --- a trailing (annotation) doesn't break the path --------------------------
out="$(run_hook "$proj/LICENSE")"
[[ -z "$out" ]] || fail "annotated boundary entry should still match its path, got: $out"

# --- a brace glob keeps its commas (they are pattern, not a separator) -------
# Splitting `{src,lib}/shared/**` on its comma would produce two broken half-patterns;
# the entry must survive whole. (Whether `case` can match a brace pattern is a separate
# question — it cannot — but a mangled entry would be a silent corruption.)
out="$(run_hook "$proj/src/other/unrelated.ts")"
assert_contains "$out" "{src,lib}/shared/**" "brace-glob entry passes through unsplit"
assert_not_contains "$out" "{src; " "brace-glob entry not split on its comma"

# --- out-of-boundary edit is denied ------------------------------------------
out="$(run_hook "$proj/src/other/unrelated.ts")"; code=$?
assert_exit 0 "$code" "deny path exits 0 (JSON decision)"
assert_contains "$out" '"permissionDecision":"deny"' "out-of-boundary edit denied"
assert_contains "$out" "export-csv" "deny reason names the work-item"
assert_contains "$out" "lcd:refine" "deny reason names the fix path"

# --- LCD artifacts and .claude are always editable ----------------------------
out="$(run_hook "$proj/docs/lcd/work/export-csv/JOURNAL.md")"
[[ -z "$out" ]] || fail "JOURNAL edit must be allowed, got: $out"
out="$(run_hook "$proj/.claude/settings.json")"
[[ -z "$out" ]] || fail ".claude edit must be allowed, got: $out"

# --- paths outside the project are not policed --------------------------------
out="$(run_hook "/somewhere/else/file.txt")"
[[ -z "$out" ]] || fail "out-of-project path must be allowed, got: $out"

# --- different branch → no active work-item → allow ---------------------------
git -C "$proj" checkout -q -b another-branch
out="$(run_hook "$proj/src/other/unrelated.ts")"
[[ -z "$out" ]] || fail "no branch match must allow, got: $out"
git -C "$proj" checkout -q feat/export-csv

# --- all steps done → work-item inactive → allow ------------------------------
sedi 's/- \[ \] S2/- [x] S2/' "$proj/docs/lcd/work/export-csv/JOURNAL.md"
out="$(run_hook "$proj/src/other/unrelated.ts")"
[[ -z "$out" ]] || fail "done work-item must not enforce, got: $out"
sedi 's/- \[x\] S2/- [ ] S2/' "$proj/docs/lcd/work/export-csv/JOURNAL.md"

# --- placeholder-only boundary → no enforcement (fail open) -------------------
sedi 's|- `src/export/`|- `<path>`|; s|- `tests/export.test.ts`|- `<path2>`|' \
  "$proj/docs/lcd/work/export-csv/JOURNAL.md"
out="$(run_hook "$proj/src/other/unrelated.ts")"
[[ -z "$out" ]] || fail "placeholder boundary must fail open, got: $out"

# --- not onboarded → allow -----------------------------------------------------
rm "$proj/.claude/rules/lcd-conventions.md"
out="$(run_hook "$proj/src/other/unrelated.ts")"
[[ -z "$out" ]] || fail "un-onboarded project must fail open, got: $out"

# --- garbage stdin → allow (fail open) -----------------------------------------
cat > "$proj/.claude/rules/lcd-conventions.md" <<'EOF'
artifact-root: docs/lcd
EOF
out="$(CLAUDE_PROJECT_DIR="$proj" bash "$PLUGIN_BIN/lcd-boundary-check.sh" <<< 'not json')"; code=$?
assert_exit 0 "$code" "garbage stdin exits 0"
[[ -z "$out" ]] || fail "garbage stdin must fail open, got: $out"

exit 0
