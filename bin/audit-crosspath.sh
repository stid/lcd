#!/usr/bin/env bash
# audit-crosspath.sh — LCD cross-path audit (the PR-creation gate), framework-agnostic.
#
# Reads <work-item>/spec.md (ACs) + <work-item>/plan.md (Cross-path matrix) and emits an
# audit table verifying every (AC × non-`none` surface) row has:
#   1. A handler at the plan-declared path, AND
#   2. A test carrying the literal string `AC-N (SURFACE)`.
#
# Zero-config: there is no per-project registry map. The plan's matrix path cell IS the
# contract. A cell is one of:
#   <file>:<token>   → grep <file> for the literal <token> (CLI command, HTTP route, MCP
#                      tool name, …). Framework-agnostic — works for any idiom.
#   <file>           → file-exists check (RENDER / DB / EVAL golden-dataset, or any surface
#                      whose contract is "this file is present").
#
# Artifact-root resolution:
#   work-item dir = $LCD_ROOT/$LCD_SPECS_DIR/<slug>
#   defaults:       LCD_ROOT = git toplevel (else pwd);  LCD_SPECS_DIR = docs/lcd/work
#
# Usage:   audit-crosspath.sh <slug>
#          LCD_ROOT=<dir> LCD_SPECS_DIR=<rel> audit-crosspath.sh <slug>   (overrides)
# Output:  audit table on stdout (markdown).
# Exit:    0 if all rows OK; 1 if any MISSING / BLOCKED.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <slug>" >&2
  exit 2
fi

slug="$1"
root="${LCD_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
specs_dir="${LCD_SPECS_DIR:-docs/lcd/work}"
spec="$root/$specs_dir/$slug/spec.md"
plan="$root/$specs_dir/$slug/plan.md"

script_dir="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$spec" ]]; then
  echo "error: spec not found: $spec" >&2
  exit 1
fi
if [[ ! -f "$plan" ]]; then
  echo "error: plan not found: $plan" >&2
  exit 1
fi

# Read AC declarations. Capture stdout and exit code separately — `mapfile < <(...)`
# does NOT propagate the subprocess exit code under `set -e`, so a malformed spec
# (parse-acs.sh exits 1) would otherwise yield empty ac_rows and a vacuous PASS.
ac_rows_raw="$(bash "$script_dir/parse-acs.sh" "$spec")" || {
  echo "error: parse-acs.sh failed for $spec (malformed spec?)" >&2
  exit 1
}
mapfile -t ac_rows <<< "$ac_rows_raw"

# Look up the plan-declared path for an (AC × surface) pair.
# Plan matrix rows look like: | `AC-6` | CLI | `src/index.ts:doctor` |
lookup_plan_path() {
  local ac="$1" surface="$2"
  awk -v ac="$ac" -v surf="$surface" '
    /^\|/ {
      gsub(/`/, "", $0)
      n = split($0, cells, "|")
      if (n >= 4) {
        a = cells[2]; s = cells[3]; p = cells[4]
        gsub(/^[ \t]+|[ \t]+$/, "", a)
        gsub(/^[ \t]+|[ \t]+$/, "", s)
        gsub(/^[ \t]+|[ \t]+$/, "", p)
        if (a == ac && s == surf) { print p; exit }
      }
    }
  ' "$plan"
}

# Check whether the plan-declared path resolves to a real handler.
#   <file>:<token> → file must exist AND contain the literal <token>.
#   <file>         → file must exist.
registry_hit() {
  local plan_path="$1"
  [[ -z "$plan_path" ]] && { echo ""; return; }
  local file_part="${plan_path%%:*}"
  local token=""
  [[ "$plan_path" == *:* ]] && token="${plan_path#*:}"
  token="$(printf '%s' "$token" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

  # plan.md is PR-modifiable content — reject paths that would escape $root.
  case "$file_part" in
    /*|*..*) echo ""; return ;;
  esac

  [[ -f "$root/$file_part" ]] || { echo ""; return; }
  if [[ -z "$token" ]]; then
    echo "$file_part"
    return
  fi
  local hit
  hit="$(grep -nF -- "$token" "$root/$file_part" | head -1 || true)"
  if [[ -n "$hit" ]]; then
    echo "$file_part:$(printf '%s' "$hit" | cut -d: -f1)"
  else
    echo ""
  fi
}

# Work-item test-scope (lean-loop, AC-4). A plan may declare
#   **Test scope:** `tests/a.sh`, `tests/sub/`
# — then ONLY files under those paths may satisfy the test gate, so a stale
# `AC-N (SURFACE)` literal left by another work-item elsewhere in the repo can
# never produce an OK row. Absent declaration → legacy repo-wide grep (older
# work-items keep auditing unchanged).
test_scope_paths() {
  sed -n 's/^\*\*Test scope:\*\*[[:space:]]*//p' "$plan" | head -1 \
    | tr -d '`' | tr ',' '\n' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed '/^$/d'
}

# Find a test carrying the literal `AC-N (SURFACE)` string — inside the plan's
# test-scope when declared, else anywhere in the repo (test name for JS/TS,
# docstring/id for pytest, comment for Go/Rust) — except the LCD artifact tree:
# tasks.md / JOURNAL checklist lines carry the same literal by convention and
# must never satisfy the gate.
test_hit() {
  local ac="$1" surface="$2"
  local lit="$ac ($surface)"
  local artifact_dir="${specs_dir%/*}"
  local hit scope declared=0 targets=()
  while IFS= read -r scope; do
    [[ -z "$scope" ]] && continue
    declared=1
    # scope cells are PR-modifiable content — reject escapes, same as plan paths.
    case "$scope" in /*|*..*) continue ;; esac
    [[ -e "$root/${scope%/}" ]] && targets+=("$root/${scope%/}")
  done < <(test_scope_paths)
  if [[ $declared -eq 1 ]]; then
    # Scope declared → it is the whole search space; a missing scope file is a miss,
    # never a fallback to the repo-wide grep.
    hit=""
    # -H: a single-file target must still print its filename (GNU grep omits it otherwise).
    [[ ${#targets[@]} -gt 0 ]] \
      && hit="$(grep -rnHF -- "$lit" "${targets[@]}" 2>/dev/null | head -1 || true)"
  else
    hit="$(grep -rnF \
        --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=target \
        --exclude-dir=dist --exclude-dir=build --exclude-dir=.worktrees \
        --exclude-dir=vendor --exclude-dir=.venv \
        -- "$lit" "$root" 2>/dev/null \
      | awk -v p="$root/$artifact_dir/" 'index($0, p) != 1' | head -1 || true)"
  fi
  if [[ -n "$hit" ]]; then
    local file line
    file="$(printf '%s' "$hit" | cut -d: -f1)"
    line="$(printf '%s' "$hit" | cut -d: -f2)"
    echo "${file##"$root"/}:$line"
  else
    echo ""
  fi
}

# Emit audit table.
printf '| AC | Surface | Handler hit | Test hit | Status |\n'
printf '|----|---------|-------------|----------|--------|\n'

any_missing=0
for row in "${ac_rows[@]}"; do
  ac="$(printf '%s' "$row" | cut -f1)"
  surfaces_csv="$(printf '%s' "$row" | cut -f2)"
  IFS=',' read -ra surfaces <<< "$surfaces_csv"
  for surface in "${surfaces[@]}"; do
    [[ "$surface" == "none" ]] && continue
    plan_path="$(lookup_plan_path "$ac" "$surface")"
    if [[ -z "$plan_path" ]]; then
      printf '| %s | %s | (no plan row) | - | BLOCKED |\n' "$ac" "$surface"
      any_missing=1
      continue
    fi
    reg="$(registry_hit "$plan_path")"
    tst="$(test_hit "$ac" "$surface")"
    if [[ -n "$reg" && -n "$tst" ]]; then
      status="OK"
    elif [[ -z "$reg" && -z "$tst" ]]; then
      status="MISSING"; any_missing=1
    elif [[ -z "$reg" ]]; then
      status="MISSING-HANDLER"; any_missing=1
    else
      status="MISSING-TEST"; any_missing=1
    fi
    printf '| %s | %s | %s | %s | %s |\n' "$ac" "$surface" "${reg:--}" "${tst:--}" "$status"
  done
done

if [[ $any_missing -eq 1 ]]; then
  exit 1
fi
