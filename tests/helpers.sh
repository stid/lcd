# Shared assertions for the LCD bin/ script tests. Source from each test file.
# Each test file exits non-zero on the first failed assertion.

PLUGIN_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" && pwd)"

fail() {
  echo "ASSERTION FAILED: $1"
  exit 1
}

# assert_exit <expected-code> <actual-code> <label>
assert_exit() {
  [[ "$2" -eq "$1" ]] || fail "$3: expected exit $1, got $2"
}

# assert_contains <haystack> <needle> <label>
assert_contains() {
  [[ "$1" == *"$2"* ]] || fail "$3: output does not contain '$2'
--- output ---
$1"
}

# assert_not_contains <haystack> <needle> <label>
assert_not_contains() {
  [[ "$1" != *"$2"* ]] || fail "$3: output unexpectedly contains '$2'
--- output ---
$1"
}

# init_tmpdir — set $tmp to a fresh tmpdir, cleaned when the test file exits
init_tmpdir() {
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
}

# sedi <sed-args…> <file> — portable in-place sed. GNU and BSD/macOS sed disagree on `-i`
# (GNU: `-i` alone; BSD: needs a backup-suffix arg), so we never use `-i`: edit to a temp,
# then move it back. Passes flags (e.g. -E) through; operates on a single file.
sedi() {
  local f="${@: -1}" tmp_f
  tmp_f="${f}.sedi.$$"
  sed "${@:1:$#-1}" "$f" > "$tmp_f" && mv "$tmp_f" "$f" || { rm -f "$tmp_f"; return 1; }
}
