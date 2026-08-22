#!/usr/bin/env bash
# Tests for bin/lcd-triage-log.sh — the triage-log write contract.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

init_tmpdir
today="$(date +%F)"

# --- triage: creates the log with header, appends the exact line shape ------
out="$(bash "$PLUGIN_BIN/lcd-triage-log.sh" triage --root "$tmp" \
  --desc "export-csv (4 files, 1 surface)" --signals 3 --lane Standard --hard no --risk no)"; code=$?
assert_exit 0 "$code" "triage append succeeds"
[[ -f "$tmp/triage-log.md" ]] || fail "log file not created"
log="$(cat "$tmp/triage-log.md")"
assert_contains "$log" "# LCD triage log" "header written on create"
assert_contains "$log" "<!-- date · work · n signals · lane · hard · risk -->" "header comment written"
expected="$today · export-csv (4 files, 1 surface) · 3 signals · Standard · hard:no · risk:no"
assert_contains "$log" "$expected" "triage line shape"
assert_contains "$out" "$expected" "appended line echoed"

# --- second append: no duplicate header, line added ------------------------
bash "$PLUGIN_BIN/lcd-triage-log.sh" triage --root "$tmp" \
  --desc "quick tweak" --signals 0 --lane Quick --hard no --risk no >/dev/null
log="$(cat "$tmp/triage-log.md")"
[[ "$(grep -c '# LCD triage log' <<<"$log")" -eq 1 ]] || fail "header duplicated on second append"
assert_contains "$log" "$today · quick tweak · 0 signals · Quick · hard:no · risk:no" "second triage line"

# --- closeout: appends the closeout shape ----------------------------------
out="$(bash "$PLUGIN_BIN/lcd-triage-log.sh" closeout --root "$tmp" \
  --slug export-csv --lane Standard --audit "PASS (test-presence)" \
  --reroutes 0 --iters 4 --interventions 0)"; code=$?
assert_exit 0 "$code" "closeout append succeeds"
assert_contains "$(cat "$tmp/triage-log.md")" \
  "$today · export-csv · closeout · Standard · audit: PASS (test-presence) · re-routes: 0 · red-green iters: 4 · interventions: 0" \
  "closeout line shape"

# --- closeout: every documented audit value accepted -----------------------
for a in "PASS (first run)" "PASS (run 3)" "n/a" "n/a (no surface)"; do
  bash "$PLUGIN_BIN/lcd-triage-log.sh" closeout --root "$tmp" \
    --slug s --lane Deep --audit "$a" --reroutes 1 --iters "n/a (docs)" \
    --interventions "2 (boundary denials)" >/dev/null || fail "audit value rejected: '$a'"
done

# --- validation: bad values reject with exit 2, nothing written ------------
before="$(wc -l < "$tmp/triage-log.md")"
out="$(bash "$PLUGIN_BIN/lcd-triage-log.sh" triage --root "$tmp" \
  --desc d --signals 2 --lane Huge --hard no --risk no 2>&1)"; code=$?
assert_exit 2 "$code" "bad lane rejects"
assert_contains "$out" "--lane must be Quick|Standard|Deep" "bad lane named"

out="$(bash "$PLUGIN_BIN/lcd-triage-log.sh" triage --root "$tmp" \
  --desc d --signals two --lane Quick --hard no --risk no 2>&1)"; code=$?
assert_exit 2 "$code" "non-integer signals rejects"

out="$(bash "$PLUGIN_BIN/lcd-triage-log.sh" closeout --root "$tmp" \
  --slug s --lane Deep --audit "PASSED" --reroutes 0 --iters 1 --interventions 0 2>&1)"; code=$?
assert_exit 2 "$code" "bad audit value rejects"
assert_contains "$out" "--audit must be" "bad audit named"

out="$(bash "$PLUGIN_BIN/lcd-triage-log.sh" closeout --root "$tmp" \
  --slug s --lane Quick --audit "n/a" --reroutes 0 --iters 1 --interventions 0 2>&1)"; code=$?
assert_exit 2 "$code" "Quick closeout rejects (Quick lane has no closeout)"

[[ "$(wc -l < "$tmp/triage-log.md")" -eq "$before" ]] || fail "rejected calls wrote to the log"

# --- missing root rejects ---------------------------------------------------
out="$(bash "$PLUGIN_BIN/lcd-triage-log.sh" triage --root "$tmp/nope" \
  --desc d --signals 0 --lane Quick --hard no --risk no 2>&1)"; code=$?
assert_exit 2 "$code" "missing artifact root rejects"

echo "test-triage-log: all assertions passed"
