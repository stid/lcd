#!/usr/bin/env bash
# Tests for bin/audit-crosspath.sh — the cross-path PR gate.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

init_tmpdir

# Build a minimal onboarded-project fixture under $tmp.
work="$tmp/docs/lcd/work/greet"
mkdir -p "$work" "$tmp/src" "$tmp/tests"

cat > "$work/spec.md" <<'EOF'
**AC-1** (surfaces: CLI, HTTP): Given a name, greet returns "hello <name>".

**AC-2** (surfaces: none): The greeter trims whitespace.
EOF

cat > "$work/plan.md" <<'EOF'
## Cross-path behavior matrix

| AC | Surface | Path |
|----|---------|------|
| `AC-1` | CLI | `src/cli.ts:greetCmd` |
| `AC-1` | HTTP | `src/http.ts:/api/greet` |
EOF

echo 'export function greetCmd() {}' > "$tmp/src/cli.ts"
echo 'app.get("/api/greet", handler)' > "$tmp/src/http.ts"
cat > "$tmp/tests/greet.test.ts" <<'EOF'
test("AC-1 (CLI): greets by name", () => {})
test("AC-1 (HTTP): greets over http", () => {})
EOF

run_audit() { LCD_ROOT="$tmp" bash "$PLUGIN_BIN/audit-crosspath.sh" greet 2>&1; }

# --- all rows OK → exit 0 ----------------------------------------------------
out="$(run_audit)"; code=$?
assert_exit 0 "$code" "fully-covered audit passes"
assert_contains "$out" "| AC-1 | CLI | src/cli.ts:1 | tests/greet.test.ts:1 | OK |" "CLI row OK"
assert_contains "$out" "| AC-1 | HTTP |" "HTTP row present"
assert_not_contains "$out" "AC-2" "none-surface AC is excluded from the audit"

# --- handler token missing → MISSING-HANDLER, exit 1 -------------------------
echo 'export function renamedCmd() {}' > "$tmp/src/cli.ts"
out="$(run_audit)"; code=$?
assert_exit 1 "$code" "missing handler token fails"
assert_contains "$out" "MISSING-HANDLER" "MISSING-HANDLER status"
echo 'export function greetCmd() {}' > "$tmp/src/cli.ts"

# --- test literal missing → MISSING-TEST, exit 1 ------------------------------
sedi 's/AC-1 (HTTP)/AC-1 HTTP/' "$tmp/tests/greet.test.ts"
out="$(run_audit)"; code=$?
assert_exit 1 "$code" "missing test literal fails"
assert_contains "$out" "MISSING-TEST" "MISSING-TEST status"
sedi 's/AC-1 HTTP/AC-1 (HTTP)/' "$tmp/tests/greet.test.ts"

# --- LCD artifact decoy must not satisfy test_hit ------------------------------
# tasks.md checklist lines carry the literal `AC-N (SURFACE)` by convention; a
# repo-wide grep would let a checklist-only AC report OK with no real test.
echo '- [ ] T-1 AC-1 (CLI) implement greet' > "$work/tasks.md"
sedi 's/AC-1 (CLI)/AC-1 CLI/' "$tmp/tests/greet.test.ts"
out="$(run_audit)"; code=$?
assert_exit 1 "$code" "tasks.md decoy does not satisfy a missing test"
assert_contains "$out" "MISSING-TEST" "decoy-only AC is MISSING-TEST"
assert_not_contains "$out" "tasks.md" "test hit never points at tasks.md"
sedi 's/AC-1 CLI/AC-1 (CLI)/' "$tmp/tests/greet.test.ts"
out="$(run_audit)"; code=$?
assert_exit 0 "$code" "real test wins with decoy present"
assert_not_contains "$out" "tasks.md" "test hit is the real test, not the decoy"
rm "$work/tasks.md"

# --- plan path escaping $root → rejected, MISSING-HANDLER ----------------------
sedi 's|src/cli.ts:greetCmd|src/../src/cli.ts:greetCmd|' "$work/plan.md"
out="$(run_audit)"; code=$?
assert_exit 1 "$code" "path with .. is rejected"
assert_contains "$out" "MISSING-HANDLER" "escaped path is MISSING-HANDLER"
sedi 's|src/\.\./src/cli.ts:greetCmd|src/cli.ts:greetCmd|' "$work/plan.md"

# --- both absent → MISSING ----------------------------------------------------
cat >> "$work/spec.md" <<'EOF'

**AC-3** (surfaces: MCP): Exposed as an MCP tool.
EOF
cat >> "$work/plan.md" <<'EOF'
| `AC-3` | MCP | `src/mcp.ts:greet_tool` |
EOF
out="$(run_audit)"; code=$?
assert_exit 1 "$code" "uncovered surface fails"
assert_contains "$out" "| AC-3 | MCP | - | - | MISSING |" "MISSING status row"

# --- no plan matrix row → BLOCKED ---------------------------------------------
sedi '/AC-3/d' "$work/plan.md"
out="$(run_audit)"; code=$?
assert_exit 1 "$code" "matrix-less AC fails"
assert_contains "$out" "| AC-3 | MCP | (no plan row) | - | BLOCKED |" "BLOCKED status row"

# --- malformed spec → hard error, no vacuous pass ------------------------------
echo '**AC-9** (surfaces: BOGUS): nope' >> "$work/spec.md"
out="$(run_audit)"; code=$?
assert_exit 1 "$code" "malformed spec fails closed"
assert_contains "$out" "parse-acs.sh failed" "malformed spec error surfaced"

exit 0
