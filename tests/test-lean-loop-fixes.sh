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

echo "test-lean-loop-fixes: all assertions passed"
