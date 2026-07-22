#!/usr/bin/env bash
# lcd-session-context.sh — SessionStart hook (all sources, incl. post-compaction).
#
# Injects ~10 lines of LCD context at session start so a cold pickup is automatic:
# artifact-root, MAP/DECISIONS paths, and any work-items active on the current branch
# with their lane + next action. When the start is a post-compaction restart
# (source == "compact") the payload additionally carries each active item's EDIT
# BOUNDARY and a trust-the-JOURNAL note — compaction is the most common in-session
# reset and the summary is not guaranteed to carry the resume spine. (PreCompact
# can't inject context — its output contract is block/allow only — so this is the
# structural injection point; see DECISIONS D-008.) Silent (no output) when the
# project isn't onboarded — zero noise on non-LCD projects.

set -uo pipefail
source "$(dirname "$0")/lcd-hooklib.sh"

payload="$(cat 2>/dev/null || true)"
src="$(lcd_json_field "$payload" source)"

lcd_resolve_project || exit 0

if [[ "$src" == "compact" ]]; then
  ctx="LCD: context was just COMPACTED. The JOURNAL resume block is ground truth — where the compaction summary and the JOURNAL disagree, trust the JOURNAL.
Artifact root: $LCD_ROOT · Map: $LCD_ROOT/MAP.md · Decisions: $LCD_ROOT/DECISIONS.md"
else
  ctx="LCD (Lean Context Development): this project is onboarded.
Artifact root: $LCD_ROOT · Map: $LCD_ROOT/MAP.md · Decisions: $LCD_ROOT/DECISIONS.md
Non-trivial new work → invoke lcd:triage (it picks the lane and states it in one line)."
fi

count=0
items=""
while IFS= read -r j; do
  [[ -n "$j" ]] || continue
  count=$((count + 1))
  [[ $count -gt 5 ]] && continue
  slug="$(basename "$(dirname "$j")")"
  lane="$(lcd_journal_field "$j" Lane)"
  next="$(lcd_journal_field "$j" "Next action")"
  items="$items
- $slug [${lane:-?}] → next: ${next:-see JOURNAL} (resume: /lcd:resume $slug)"
  if [[ "$src" == "compact" ]]; then
    boundary="$(lcd_journal_boundary "$j" | head -8 | paste -sd ',' - | sed 's/,/, /g')"
    [[ -n "$boundary" ]] && items="$items
  edit boundary: $boundary"
  fi
done < <(lcd_active_journals)

if [[ $count -gt 0 ]]; then
  ctx="$ctx
Active work-item(s) on this branch:$items"
  [[ $count -gt 5 ]] && ctx="$ctx
…and $((count - 5)) more under $LCD_ROOT/work/."
else
  ctx="$ctx
No work-item is active on this branch."
fi

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
  "$(lcd_json_escape "$ctx")"
exit 0
