#!/usr/bin/env bash
# Tests for tests/helpers.sh itself — the shared lib every fixture test trusts.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
init_tmpdir

# --- sedi edits in place ---
printf '#!/bin/sh\necho hello\n' > "$tmp/script.sh"
chmod +x "$tmp/script.sh"
sedi 's/hello/world/' "$tmp/script.sh"
out="$(cat "$tmp/script.sh")"
assert_contains "$out" "echo world" "sedi: replacement applied"
assert_not_contains "$out" "echo hello" "sedi: old text gone"

# --- sedi preserves the executable bit (regression: mv dropped it) ---
[[ -x "$tmp/script.sh" ]] || fail "sedi: executable bit dropped after in-place edit"

# --- sedi leaves no temp file behind ---
leftovers="$(ls "$tmp" | grep -c '\.sedi\.' || true)"
[[ "$leftovers" -eq 0 ]] || fail "sedi: temp file left behind"

# --- sedi returns non-zero on a missing file and leaves no temp ---
if sedi 's/a/b/' "$tmp/nope.txt" 2>/dev/null; then
  fail "sedi: expected non-zero exit on missing file"
fi

echo "test-helpers: all assertions passed"
