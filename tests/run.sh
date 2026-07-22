#!/usr/bin/env bash
# Test runner for the LCD plugin's bin/ scripts. Plain bash, no dependencies.
# Usage: tests/run.sh [test-file-substring]
set -uo pipefail

tests_dir="$(cd "$(dirname "$0")" && pwd)"
filter="${1:-}"

total=0
failed=0
for t in "$tests_dir"/test-*.sh; do
  [[ -n "$filter" && "$t" != *"$filter"* ]] && continue
  total=$((total + 1))
  name="$(basename "$t")"
  if out="$(bash "$t" 2>&1)"; then
    echo "PASS $name"
  else
    failed=$((failed + 1))
    echo "FAIL $name"
    echo "$out" | sed 's/^/  | /'
  fi
done

echo "----"
echo "$((total - failed))/$total test files passed"
[[ $failed -eq 0 ]]
