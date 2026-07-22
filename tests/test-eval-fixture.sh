#!/usr/bin/env bash
# Integrity test for evals/fixture — the frozen, pre-onboarded sandbox project the
# benchmark copies per run (work-item: eval-harness). Deterministic: no model involved.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$plugin_root/evals/fixture"

[[ -d "$fixture" ]] || fail "evals/fixture does not exist"

# --- shape: CLI + HTTP sharing one core, no external deps -------------------------
for f in package.json cli.js server.js core.js; do
  [[ -f "$fixture/$f" ]] || fail "fixture missing $f"
done
grep -q '"dependencies"' "$fixture/package.json" \
  && fail "fixture must have no external dependencies" || true

# --- pre-onboarded LCD state (determinism: no /onboard variance per run) ----------
[[ -f "$fixture/.claude/rules/lcd-conventions.md" ]] || fail "fixture not onboarded (conventions missing)"
grep -q 'artifact-root: docs/lcd' "$fixture/.claude/rules/lcd-conventions.md" \
  || fail "fixture conventions must pin artifact-root docs/lcd"
[[ -f "$fixture/docs/lcd/MAP.md" ]] || fail "fixture MAP.md missing"
[[ -f "$fixture/docs/lcd/DECISIONS.md" ]] || fail "fixture DECISIONS.md missing"

# --- starter suite is green (the baseline every run starts from) ------------------
out="$( (cd "$fixture" && node --test) 2>&1 )"; code=$?
assert_exit 0 "$code" "fixture starter suite green
$out"

# --- the scripted feature is NOT pre-implemented (the run has work to do) ---------
grep -rq 'stats' "$fixture/core.js" && fail "fixture must not pre-implement the stats feature" || true

exit 0
