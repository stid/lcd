#!/usr/bin/env bash
# Tests for evals/grade.sh — the mechanical grader (work-item: eval-harness).
# AC-3 locks the grader's output to the frozen golden workspace: any intentional
# grader change must update evals/golden/expected-row.txt in the same commit.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
grader="$plugin_root/evals/grade.sh"
golden_src="$plugin_root/evals/golden/workspace"
expected="$plugin_root/evals/golden/expected-row.txt"

[[ -f "$grader" ]] || fail "evals/grade.sh does not exist"
[[ -d "$golden_src" ]] || fail "evals/golden/workspace does not exist"
[[ -f "$expected" ]] || fail "evals/golden/expected-row.txt does not exist"

init_tmpdir

# Materialize the golden workspace deterministically: fixed dir name, fixed git
# history (baseline tag + one scaffold commit + one red→green commit).
ws="$tmp/stats-golden"
cp -R "$golden_src" "$ws"
git -C "$ws" init -q
gc() { git -C "$ws" -c user.email=test@example.invalid -c user.name=test \
         -c commit.gpgsign=false commit -q --allow-empty "$@"; }
git -C "$ws" add -A && gc -m 'baseline'
git -C "$ws" tag eval-baseline
gc -m 'chore(stats-surfaces): scaffold'
gc -m 'feat(stats-surfaces): pass AC-1 (CLI)'

# --- AC-2 (CLI): grader emits exactly one metric row and exits 0 ------------------
out="$(bash "$grader" "$ws" stats-surfaces golden 2>/dev/null)"; code=$?
assert_exit 0 "$code" "AC-2 (CLI): grader exits 0 on a completed workspace"
[[ "$(printf '%s\n' "$out" | wc -l)" -eq 1 ]] || fail "AC-2 (CLI): exactly one row, got: $out"
assert_contains "$out" 'audit: ' "AC-2 (CLI): row carries the audit metric"
assert_contains "$out" 'suite: ' "AC-2 (CLI): row carries the suite metric"
assert_contains "$out" 'commits: ' "AC-2 (CLI): row carries the commit counts"
assert_contains "$out" 'tokens: ' "AC-2 (CLI): row carries the token metric"

# --- AC-3 (EVAL): the row matches the frozen expected row exactly ----------------
normalized="$(printf '%s' "$out" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}/DATE/')"
[[ "$normalized" == "$(cat "$expected")" ]] \
  || fail "AC-3 (EVAL): golden lock broken
--- got ---
$normalized
--- expected ---
$(cat "$expected")"

# --- a BLOCKED workspace still grades (exit 0) and says BLOCKED -------------------
ws2="$tmp/blocked-ws"
cp -R "$golden_src" "$ws2"
rm -f "$ws2/cli.js"   # break the CLI handler → audit must report non-OK rows
git -C "$ws2" init -q
git -C "$ws2" add -A
git -C "$ws2" -c user.email=test@example.invalid -c user.name=test \
  -c commit.gpgsign=false commit -qm baseline
git -C "$ws2" tag eval-baseline
out="$(bash "$grader" "$ws2" stats-surfaces golden 2>/dev/null)"; code=$?
assert_exit 0 "$code" "grading a failed run still exits 0 (the row IS the result)"
assert_contains "$out" 'audit: BLOCKED' "broken handler graded as BLOCKED"

# --- missing workspace → fail closed ----------------------------------------------
out="$(bash "$grader" "$tmp/empty-nowhere" stats-surfaces golden 2>&1)"; code=$?
assert_exit 2 "$code" "missing workspace fails closed"

# --- LCD workspace whose run died before spec+plan → INCOMPLETE row, not a crash ----
ws3="$tmp/incomplete-ws"
mkdir -p "$ws3/docs/lcd/work/stats-surfaces"
echo '# spec only' > "$ws3/docs/lcd/work/stats-surfaces/spec.md"
out="$(bash "$grader" "$ws3" stats-surfaces golden 2>/dev/null)"; code=$?
assert_exit 0 "$code" "incomplete run still grades (the row is the verdict)"
assert_contains "$out" 'audit: INCOMPLETE' "incomplete run recorded as INCOMPLETE"

exit 0
