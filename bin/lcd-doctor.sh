#!/usr/bin/env bash
# lcd-doctor.sh — validate a project's LCD conventions (the executable form of the
# "sanity checks before trusting this file" checklist in the lcd-conventions template).
#
# Checks the machine block of .claude/rules/lcd-conventions.md plus the artifacts it
# points at. Read-only. Output: one `OK|WARN|FAIL — <check>: <detail>` line per check.
# Exit: 0 when no FAIL (WARNs allowed); 1 otherwise.
#
# Usage: lcd-doctor.sh [project-dir]   (default: $CLAUDE_PROJECT_DIR, else pwd)

set -uo pipefail

proj="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
conv="$proj/.claude/rules/lcd-conventions.md"
fails=0
warns=0

ok()   { printf 'OK   — %s\n' "$1"; }
warn() { printf 'WARN — %s\n' "$1"; warns=$((warns+1)); }
fail() { printf 'FAIL — %s\n' "$1"; fails=$((fails+1)); }

get_key() { sed -n "s/^$1:[[:space:]]*//p" "$conv" | head -1; }

# Unfilled template placeholders are ALL-CAPS (`<SCOPED_CMD>`); lowercase angle tokens
# (`<slug>`, `<surface>`, `<name>`) are legitimate per-test substitution markers.
is_placeholder() { grep -qE '<[A-Z][A-Z_]*>' <<< "$1"; }

# --- the conventions file itself --------------------------------------------
if [[ ! -f "$conv" ]]; then
  fail "conventions: $conv not found — project is not onboarded (run /lcd:onboard)"
  echo "----"
  echo "doctor: 1 FAIL"
  exit 1
fi
if grep -q '<!-- lcd-conventions:v1 -->' "$conv"; then
  ok "conventions: machine block marker present"
else
  fail "conventions: missing '<!-- lcd-conventions:v1 -->' marker — the suite can't find the machine block"
fi

# --- keys present and placeholder-free ---------------------------------------
required_keys=(artifact-root scoped-test bail single-test gate)
recommended_keys=(test-placement test-discovery-glob eval maintenance-bundle)
for k in "${required_keys[@]}"; do
  v="$(get_key "$k")"
  if [[ -z "$v" ]]; then
    fail "key '$k': missing — the red-green loop / Deep pipeline can't run without it"
  elif is_placeholder "$v"; then
    fail "key '$k': still a placeholder ('$v') — onboarding never filled it in"
  else
    ok "key '$k': $v"
  fi
done
for k in "${recommended_keys[@]}"; do
  v="$(get_key "$k")"
  if [[ -z "$v" ]] || is_placeholder "$v"; then
    warn "key '$k': missing or placeholder — fill it so the suite doesn't have to guess"
  else
    ok "key '$k': $v"
  fi
done

# --- watch-mode commands hang the autonomous loop -----------------------------
for k in scoped-test bail single-test; do
  v="$(get_key "$k")"
  [[ -n "$v" ]] && ! is_placeholder "$v" || continue
  if [[ "$v" == *vitest* && "$v" != *"vitest run"* ]]; then
    fail "key '$k': '$v' — bare vitest enters watch mode; use 'vitest run …'"
  elif [[ "$v" == *jest* && "$v" != *--watchAll=false* && "$v" != *--ci* ]]; then
    fail "key '$k': '$v' — jest watches by default; add '--watchAll=false' (or --ci)"
  fi
done

# --- artifacts the block points at --------------------------------------------
root="$(get_key artifact-root)"
if [[ -n "$root" ]] && ! is_placeholder "$root"; then
  root="${root%/}"
  [[ -d "$proj/$root" ]] && ok "artifact-root: $root/ exists" \
    || warn "artifact-root: $proj/$root does not exist yet (created on first use)"
  [[ -f "$proj/$root/MAP.md" ]] && ok "MAP: $root/MAP.md exists" \
    || warn "MAP: $root/MAP.md missing — cold starts lose their guardrails (re-run /lcd:onboard)"
  [[ -f "$proj/$root/DECISIONS.md" ]] && ok "DECISIONS: $root/DECISIONS.md exists" \
    || warn "DECISIONS: $root/DECISIONS.md missing"

  # living-spec is opt-in: when 'on', the SPEC.md it points at must exist for reconcile to fold into.
  if [[ "$(get_key living-spec)" == "on" ]]; then
    specrel="$(get_key spec)"; specrel="${specrel:-$root/SPEC.md}"
    [[ -f "$proj/$specrel" ]] && ok "living-spec: on; $specrel exists" \
      || warn "living-spec: on but $specrel missing — reconcile has nowhere to fold (seed it from the living-spec template, or set living-spec: off)"
  fi

  # B1 invariant: non-default root needs the project-local ac-convention override.
  if [[ "$root" != "docs/lcd" ]]; then
    acf="$proj/.claude/rules/ac-convention.md"
    if [[ -f "$acf" ]] && grep -q "$root" "$acf"; then
      ok "ac-convention: project override present for non-default root"
    else
      fail "ac-convention: artifact-root is '$root' but no project override at .claude/rules/ac-convention.md covers it — the AC rule will never auto-load (re-run /lcd:onboard)"
    fi
  fi
fi

# --- CLAUDE.md pointer ----------------------------------------------------------
if [[ -f "$proj/CLAUDE.md" ]] && grep -q 'lcd:triage' "$proj/CLAUDE.md"; then
  ok "CLAUDE.md: LCD pointer present"
else
  warn "CLAUDE.md: no LCD pointer — triage won't be suggested on new work (re-run /lcd:onboard)"
fi

# --- placement vs discovery glob (cheap heuristic) -------------------------------
placement="$(get_key test-placement)"
glob="$(get_key test-discovery-glob)"
if [[ -n "$placement" && -n "$glob" ]] && ! is_placeholder "$placement" && ! is_placeholder "$glob"; then
  pext="${placement##*.}"
  if [[ "$glob" == *"$pext"* || "$glob" == *"{"* ]]; then
    ok "test-placement: extension .$pext is covered by discovery glob"
  else
    warn "test-placement: '$placement' may not match discovery glob '$glob' — generated tests would be silently ignored by the runner"
  fi
fi

echo "----"
echo "doctor: $fails FAIL, $warns WARN"
[[ $fails -eq 0 ]]
