#!/usr/bin/env bash
# grade.sh — mechanical grader for one prompt-eval run (work-item: eval-harness).
#
# Points at a completed run workspace and emits ONE metric row on stdout:
#   <date> · <arm> · <ws> · audit: PASS|BLOCKED (<n> non-OK) · suite: green|red|n/a
#   · commits: <n> (redgreen: <n>) · tokens: <n|n/a> · interventions: n/a
#
# The grader is regression-locked: tests/test-eval-grade.sh compares its output on
# evals/golden/workspace against evals/golden/expected-row.txt. Any intentional change
# here must update that expected row in the same commit.
#
# Exit: 0 once a row is emitted (a BLOCKED/red row IS a valid result — the row is the
# verdict, not the grader's exit code); 2 on unusable input (fail closed: this is an
# instrument, unlike the plugin's fail-open hooks).
#
# Usage: grade.sh <workspace-dir> <slug> [arm]

set -uo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <workspace-dir> <slug> [arm]" >&2
  exit 2
fi

ws="$1"; slug="$2"; arm="${3:--}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
plugin_bin="$script_dir/../bin"

[[ -d "$ws" ]] || { echo "error: workspace not found: $ws" >&2; exit 2; }
[[ -d "$ws/docs/lcd" ]] || { echo "error: $ws is not an LCD workspace" >&2; exit 2; }
work="$ws/docs/lcd/work/$slug"

# --- audit (the same cross-path gate the methodology ships) ------------------------
# A run that stopped before producing spec+plan is a valid (failed) result, not a
# grader error: record it as INCOMPLETE so the experiment row still lands.
if [[ -f "$work/spec.md" && -f "$work/plan.md" ]]; then
  table="$(LCD_ROOT="$ws" LCD_SPECS_DIR="docs/lcd/work" bash "$plugin_bin/audit-crosspath.sh" "$slug" 2>/dev/null)"
  if [[ $? -eq 0 ]]; then audit_res="PASS"; else audit_res="BLOCKED"; fi
  nonok="$(printf '%s\n' "$table" \
    | grep -cE '\|[[:space:]]*(MISSING|MISSING-HANDLER|MISSING-TEST|BLOCKED)[[:space:]]*\|$' || true)"
else
  audit_res="INCOMPLETE"; nonok="n/a"
fi

# --- full fixture suite -------------------------------------------------------------
suite="n/a"
if [[ -f "$ws/package.json" && -d "$ws/tests" ]]; then
  # bare discovery (**/*.test.js) — `node --test tests/` misparses on some node 22 builds
  if (cd "$ws" && node --test >/dev/null 2>&1); then suite="green"; else suite="red"; fi
fi

# --- commit counts since the run baseline -------------------------------------------
commits="n/a"; redgreen="n/a"
if git -C "$ws" rev-parse -q --verify eval-baseline >/dev/null 2>&1; then
  commits="$(git -C "$ws" rev-list --count eval-baseline..HEAD 2>/dev/null || echo n/a)"
  redgreen="$(git -C "$ws" log --format=%s eval-baseline..HEAD 2>/dev/null | grep -c 'pass AC-' || true)"
fi

# --- token volume + cash cost summed across the run legs ----------------------------
# Metric v2 (2026-06-11): read modelUsage, not .usage — .usage misses subagent calls
# (a fan-out run under-reported 4x), and counting creation-without-reads made the number
# scheduling-dependent (a run riding a concurrent run's prompt cache looked 4x cheaper).
# volume = in + cache_creation + cache_read + out over every model — scheduling-invariant.
# cost = total_cost_usd — the real cash number (cache-discount sensitive by nature).
tokens="n/a"; cost="n/a"
if command -v jq >/dev/null 2>&1; then
  legs=("$ws"/run*.json)
  if [[ -f "${legs[0]:-}" ]]; then
    t="$(jq -rs 'map(.modelUsage // {} | to_entries | map(.value
           | (.inputTokens // 0) + (.cacheCreationInputTokens // 0)
           + (.cacheReadInputTokens // 0) + (.outputTokens // 0)) | add // 0) | add' \
         "${legs[@]}" 2>/dev/null || true)"
    [[ -n "$t" && "$t" != "0" && "$t" != "null" ]] && tokens="$t"
    c="$(jq -rs 'map(.total_cost_usd // 0) | add | .*100 | round / 100' \
         "${legs[@]}" 2>/dev/null || true)"
    [[ -n "$c" && "$c" != "0" && "$c" != "null" ]] && cost="\$$c"
  fi
fi

emit_row() {
  printf '%s · %s · %s · audit: %s (%s non-OK) · suite: %s · commits: %s (redgreen: %s) · tokens: %s · cost: %s · interventions: n/a\n' \
    "$(date +%F)" "$arm" "$(basename "$ws")" \
    "$audit_res" "$nonok" "$suite" "$commits" "$redgreen" "$tokens" "$cost"
}

emit_row
exit 0
