#!/usr/bin/env bash
# lcd-boundary-check.sh — PreToolUse hook (Edit|Write|MultiEdit|NotebookEdit).
#
# Makes the EDIT BOUNDARY structural: while a work-item is ACTIVE on the current branch
# (its JOURNAL **Branch:** matches HEAD and it still has unchecked STEPS), edits outside
# the union of active EDIT BOUNDARY entries are DENIED with a reason that names the fix
# (update the boundary via lcd:refine — never bypass it silently).
#
# Fail-open by design: not onboarded / no active work-item / empty boundary / unparseable
# input → allow. The artifact root and .claude/ are always editable (the loop must be able
# to update the JOURNAL itself).

set -uo pipefail
source "$(dirname "$0")/lcd-hooklib.sh"

input="$(cat)"

lcd_resolve_project || exit 0

file_path="$(lcd_json_field "$input" "tool_input.file_path")"
[[ -n "$file_path" ]] || exit 0

# Normalize to project-relative; paths outside the project are not ours to police.
case "$file_path" in
  "$LCD_PROJ"/*) rel="${file_path#"$LCD_PROJ"/}" ;;
  /*) exit 0 ;;
  *) rel="$file_path" ;;
esac

# Always-allowed: LCD's own artifacts and project Claude config.
case "$rel" in
  "$LCD_ROOT"/*|.claude/*|CLAUDE.md) exit 0 ;;
esac

# Collect the union boundary across active work-items on this branch.
boundary=()
slugs=""
while IFS= read -r j; do
  [[ -n "$j" ]] || continue
  while IFS= read -r entry; do
    [[ -n "$entry" ]] && boundary+=("$entry")
  done < <(lcd_journal_boundary "$j")
  slug="$(basename "$(dirname "$j")")"
  slugs="${slugs:+$slugs, }$slug"
done < <(lcd_active_journals)

# No active work-item, or boundary not filled in → nothing to enforce.
[[ ${#boundary[@]} -gt 0 ]] || exit 0

for entry in "${boundary[@]}"; do
  entry="${entry%/}"
  # Exact path, path under a boundary dir, or glob entry (case patterns honor *).
  case "$rel" in
    $entry|$entry/*) exit 0 ;;
  esac
done

reason="LCD edit boundary: '$rel' is outside the EDIT BOUNDARY of the active work-item(s) [$slugs] on this branch. Boundary: $(printf '%s; ' "${boundary[@]}")— if the plan legitimately needs this path, first add it to the JOURNAL EDIT BOUNDARY (lcd:refine, logged), then retry the edit."
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' \
  "$(lcd_json_escape "$reason")"
exit 0
