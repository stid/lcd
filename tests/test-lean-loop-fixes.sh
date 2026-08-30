#!/usr/bin/env bash
# Tests for the lean-loop fixes (work-item lean-loop, over-engineering audit follow-through):
#   AC-1 (CLI): closeout contract — iters optional, other fields mandatory, dual line shape
#   AC-4 (CLI): audit test grep honors the plan's test-scope (stale foreign literals rejected)
#   AC-5 (CLI): boundary hook brace-expand — {a,b} alternatives actually match
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

init_tmpdir
today="$(date +%F)"

# ============================================================================
# AC-1 (CLI): closeout mandatory flags + optional iters, dual-shape validate
# ============================================================================
mkdir -p "$tmp/rootA"

# New shape: --iters omitted → succeeds, line carries no "red-green iters" field.
out="$(bash "$PLUGIN_BIN/lcd-triage-log.sh" closeout --root "$tmp/rootA" \
  --slug lean --lane Standard --audit "n/a" --reroutes 0 --interventions 0)"; code=$?
assert_exit 0 "$code" "AC-1 (CLI): closeout without --iters succeeds"
assert_contains "$out" \
  "$today · lean · closeout · Standard · audit: n/a · re-routes: 0 · interventions: 0" \
  "AC-1 (CLI): new-shape line has mandatory fields in order"
assert_not_contains "$out" "red-green iters" "AC-1 (CLI): new-shape line omits iters field"

# Old shape still accepted: --iters given → field present (existing logs stay valid).
out="$(bash "$PLUGIN_BIN/lcd-triage-log.sh" closeout --root "$tmp/rootA" \
  --slug lean --lane Deep --audit "PASS (first run)" --reroutes 1 --iters 4 --interventions 0)"; code=$?
assert_exit 0 "$code" "AC-1 (CLI): closeout with --iters still succeeds (old shape)"
assert_contains "$out" "red-green iters: 4" "AC-1 (CLI): old-shape line keeps iters field"

# Mandatory fields stay mandatory: each missing one → exit 2, nothing written.
before="$(wc -l < "$tmp/rootA/triage-log.md")"
for missing in lane audit reroutes interventions; do
  args=(--root "$tmp/rootA" --slug s)
  [[ "$missing" != "lane" ]] && args+=(--lane Standard)
  [[ "$missing" != "audit" ]] && args+=(--audit "n/a")
  [[ "$missing" != "reroutes" ]] && args+=(--reroutes 0)
  [[ "$missing" != "interventions" ]] && args+=(--interventions 0)
  bash "$PLUGIN_BIN/lcd-triage-log.sh" closeout "${args[@]}" >/dev/null 2>&1; code=$?
  assert_exit 2 "$code" "AC-1 (CLI): closeout without --$missing rejects"
done
[[ "$(wc -l < "$tmp/rootA/triage-log.md")" -eq "$before" ]] \
  || fail "AC-1 (CLI): rejected closeouts wrote to the log"

# ============================================================================
# AC-4 (CLI): audit test grep honors the plan's test-scope declaration
# ============================================================================
# The T1 stale-literal case: a foreign file elsewhere in the repo carries the
# literal `AC-N (SURFACE)` left by an older work-item. With a test-scope declared
# in plan.md, only files under that scope may satisfy the gate.
proj="$tmp/projB"
work="$proj/docs/lcd/work/lean"
mkdir -p "$work" "$proj/src" "$proj/tests" "$proj/old"

cat > "$work/spec.md" <<'EOF'
**AC-1** (surfaces: CLI): Given a name, greet returns hello.
EOF
cat > "$work/plan.md" <<'EOF'
## Cross-path behavior matrix

| AC | Surface | Path |
|----|---------|------|
| `AC-1` | CLI | `src/cli.ts:greetCmd` |

**Test scope:** `tests/lean.test.ts`
EOF
echo 'export function greetCmd() {}' > "$proj/src/cli.ts"
# Stale foreign literal from an old work-item — must NOT satisfy the scoped gate.
echo 'test("AC-1 (CLI): old stale test", () => {})' > "$proj/old/stale.test.ts"

out="$(LCD_ROOT="$proj" LCD_SPECS_DIR=docs/lcd/work bash "$PLUGIN_BIN/audit-crosspath.sh" lean 2>&1)"; code=$?
assert_exit 1 "$code" "AC-4 (CLI): stale foreign literal outside test-scope no longer yields OK"
assert_contains "$out" "MISSING-TEST" "AC-4 (CLI): scoped miss is MISSING-TEST"
assert_not_contains "$out" "old/stale.test.ts" "AC-4 (CLI): test hit never points at the stale file"

# The real, in-scope test satisfies the gate — and the hit points inside the scope.
echo 'test("AC-1 (CLI): greets", () => {})' > "$proj/tests/lean.test.ts"
out="$(LCD_ROOT="$proj" LCD_SPECS_DIR=docs/lcd/work bash "$PLUGIN_BIN/audit-crosspath.sh" lean 2>&1)"; code=$?
assert_exit 0 "$code" "AC-4 (CLI): in-scope test passes"
assert_contains "$out" "tests/lean.test.ts" "AC-4 (CLI): hit points at the scoped test"

# Backward compatibility: no test-scope in plan → repo-wide behavior unchanged.
sedi '/Test scope/d' "$work/plan.md"
rm "$proj/tests/lean.test.ts"
out="$(LCD_ROOT="$proj" LCD_SPECS_DIR=docs/lcd/work bash "$PLUGIN_BIN/audit-crosspath.sh" lean 2>&1)"; code=$?
assert_exit 0 "$code" "AC-4 (CLI): scope-less plan keeps legacy repo-wide grep"

# ============================================================================
# AC-5 (CLI): boundary hook brace-expand — {a,b} alternatives actually match
# ============================================================================
# Before the fix, `{src,lib}/shared/**` passed through unsplit but could never
# match in `case` — every edit under such a boundary entry was silently denied.
projC="$tmp/projC"
mkdir -p "$projC/.claude/rules" "$projC/docs/lcd/work/braces" \
         "$projC/src/shared" "$projC/lib/shared" "$projC/src/other"
git -C "$projC" init -q -b feat/braces

cat > "$projC/.claude/rules/lcd-conventions.md" <<'EOF'
<!-- lcd-conventions:v1 -->
artifact-root: docs/lcd
<!-- /lcd-conventions -->
EOF

cat > "$projC/docs/lcd/work/braces/JOURNAL.md" <<'EOF'
<!-- lcd-resume:v1 -->
## NOW
- **Lane:** Standard
- **Branch:** feat/braces  ·  **Updated:** 2026-08-30

## STEPS
- [ ] S1 — pending  ← next

## EDIT BOUNDARY (paths this work may touch)
- `{src,lib}/shared/**`
<!-- /lcd-resume -->
EOF

run_boundary() {
  CLAUDE_PROJECT_DIR="$projC" bash "$PLUGIN_BIN/lcd-boundary-check.sh" <<EOF
{"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"$1"}}
EOF
}

out="$(run_boundary "$projC/src/shared/util.ts")"; code=$?
assert_exit 0 "$code" "AC-5 (CLI): brace alternative exits 0"
[[ -z "$out" ]] || fail "AC-5 (CLI): edit under first brace alternative must be allowed, got: $out"

out="$(run_boundary "$projC/lib/shared/util.ts")"
[[ -z "$out" ]] || fail "AC-5 (CLI): edit under second brace alternative must be allowed, got: $out"

out="$(run_boundary "$projC/src/other/file.ts")"
assert_contains "$out" '"permissionDecision":"deny"' \
  "AC-5 (CLI): path outside every brace alternative is still denied"

echo "test-lean-loop-fixes: all assertions passed"
