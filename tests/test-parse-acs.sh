#!/usr/bin/env bash
# Tests for bin/parse-acs.sh — the AC extraction contract.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

init_tmpdir

# --- well-formed spec: all surface shapes parse, bodies survive -------------
cat > "$tmp/spec.md" <<'EOF'
# Spec

**AC-1** (surfaces: CLI, HTTP, MCP): Given a key, when resolved, then env wins.

**AC-2** (surfaces: HTTP): Given /api/doctor, then key_source is "env".

**AC-3** (surfaces: none): The resolver returns the first non-empty source.

**AC-4** (surfaces: EVAL): Given the frozen set, MAE stays at or below 0.15.
EOF
out="$(bash "$PLUGIN_BIN/parse-acs.sh" "$tmp/spec.md")"; code=$?
assert_exit 0 "$code" "well-formed spec parses"
assert_contains "$out" "$(printf 'AC-1\tCLI,HTTP,MCP\tGiven a key, when resolved, then env wins.')" "AC-1 row"
assert_contains "$out" "$(printf 'AC-2\tHTTP\t')" "AC-2 row"
assert_contains "$out" "$(printf 'AC-3\tnone\t')" "AC-3 none row"
assert_contains "$out" "$(printf 'AC-4\tEVAL\t')" "AC-4 EVAL row"
[[ "$(echo "$out" | wc -l)" -eq 4 ]] || fail "expected exactly 4 rows, got: $out"

# --- invalid surface token rejects (typo guard) -----------------------------
cat > "$tmp/spaced.md" <<'EOF'
**AC-1** (surfaces:   CLI ,  none2x ): body
EOF
out="$(bash "$PLUGIN_BIN/parse-acs.sh" "$tmp/spaced.md" 2>&1)"; code=$?
assert_exit 1 "$code" "invalid token rejects"
assert_contains "$out" "invalid surface token 'none2x'" "invalid token named in error"

# --- none must not mix with other surfaces ----------------------------------
cat > "$tmp/mixed.md" <<'EOF'
**AC-1** (surfaces: CLI, none): body
EOF
out="$(bash "$PLUGIN_BIN/parse-acs.sh" "$tmp/mixed.md" 2>&1)"; code=$?
assert_exit 1 "$code" "none+surface mix rejects"
assert_contains "$out" "mixes 'none' with other surface tokens" "mix error message"

# --- malformed AC line (no surfaces tag) ------------------------------------
cat > "$tmp/malformed.md" <<'EOF'
**AC-1**: body without a surfaces tag
EOF
out="$(bash "$PLUGIN_BIN/parse-acs.sh" "$tmp/malformed.md" 2>&1)"; code=$?
assert_exit 1 "$code" "malformed AC rejects"
assert_contains "$out" "malformed AC line" "malformed error message"

# --- spec with zero ACs ------------------------------------------------------
cat > "$tmp/empty.md" <<'EOF'
# A spec with prose but no acceptance criteria.
EOF
out="$(bash "$PLUGIN_BIN/parse-acs.sh" "$tmp/empty.md" 2>&1)"; code=$?
assert_exit 1 "$code" "zero-AC spec rejects"
assert_contains "$out" "no AC declarations found" "zero-AC error message"

# --- missing file ------------------------------------------------------------
out="$(bash "$PLUGIN_BIN/parse-acs.sh" "$tmp/nope.md" 2>&1)"; code=$?
assert_exit 1 "$code" "missing file rejects"

exit 0
