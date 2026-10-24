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
# NotebookEdit names its target notebook_path, not file_path.
[[ -n "$file_path" ]] || file_path="$(lcd_json_field "$input" "tool_input.notebook_path")"
[[ -n "$file_path" ]] || exit 0

# resolve_dots <abs-path> — drop `.` and resolve `..` lexically (the file may not exist yet),
# so `src/x/../../docs/y` is matched as `docs/y`, not as a path under src/.
resolve_dots() {
  local part parts out=()
  IFS=/ read -ra parts <<<"$1"
  for part in ${parts[@]+"${parts[@]}"}; do
    case "$part" in
      ""|.) ;;
      ..) [[ ${#out[@]} -gt 0 ]] && unset 'out[${#out[@]}-1]' ;;
      *) out+=("$part") ;;
    esac
  done
  printf '/%s' ${out[@]+"${out[@]}"}
}

# Normalize to project-relative; paths outside the project are not ours to police.
[[ "$file_path" == /* ]] || file_path="$LCD_PROJ/$file_path"
file_path="$(resolve_dots "$file_path")"
proj_abs="$(resolve_dots "$LCD_PROJ")"
case "$file_path" in
  "$proj_abs"/*) rel="${file_path#"$proj_abs"/}" ;;
  *) exit 0 ;;
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
  # Brace entries are expanded to their alternatives at match time (lcd_expand_braces
  # in hooklib) — `case` never brace-expands, so matching the raw `{a,b}` entry would
  # silently deny everything under it. The deny reason below keeps the original entry.
  while IFS= read -r exp; do
    # Exact path, path under a boundary dir, or glob entry (case patterns honor *).
    case "$rel" in
      $exp|$exp/*) exit 0 ;;
    esac
  done < <(lcd_expand_braces "$entry")
done

reason="LCD edit boundary: '$rel' is outside the EDIT BOUNDARY of the active work-item(s) [$slugs] on this branch. Boundary: $(printf '%s; ' "${boundary[@]}")— if the plan legitimately needs this path, first add it to the JOURNAL EDIT BOUNDARY (lcd:refine, logged), then retry the edit."
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' \
  "$(lcd_json_escape "$reason")"
exit 0
