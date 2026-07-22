#!/usr/bin/env bash
# lcd-staleness-check.sh — Stop hook.
#
# A stale resume anchor lies to the next session — worse than none. When a work-item is
# ACTIVE on the current branch (Branch matches HEAD, unchecked STEPS) and commits landed
# after the JOURNAL's **Updated:** date, block the stop ONCE with instructions to bring
# NOW/STEPS/Updated current. Same-day granularity (date-only compare) keeps it from
# nagging mid-flow; `stop_hook_active` prevents a blocking loop.
#
# Fail-open like every LCD hook: not onboarded / no active item / no commits → allow.

set -uo pipefail
source "$(dirname "$0")/lcd-hooklib.sh"

input="$(cat)"

# Never block twice in a row — if we already blocked and Claude is finishing up, let it stop.
[[ "$(lcd_json_field "$input" "stop_hook_active")" == "true" ]] && exit 0

lcd_resolve_project || exit 0

head_date="$(git -C "$LCD_PROJ" log -1 --format=%cd --date=short 2>/dev/null)" || exit 0
[[ -n "$head_date" ]] || exit 0

stale=""
while IFS= read -r j; do
  [[ -n "$j" ]] || continue
  updated="$(lcd_journal_field "$j" Updated)"
  updated="${updated%% *}"
  [[ "$updated" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue
  if [[ "$head_date" > "$updated" ]]; then
    slug="$(basename "$(dirname "$j")")"
    stale="${stale:+$stale, }$slug (JOURNAL Updated $updated < last commit $head_date)"
  fi
done < <(lcd_active_journals)

[[ -n "$stale" ]] || exit 0

echo "LCD: the resume anchor is stale for active work-item(s): $stale. Before finishing, update the JOURNAL's lcd-resume block — tick completed STEPS, set NOW.Next-action to the true next step, and refresh the **Updated:** date — so the next cold session resumes from reality, not history. Then finish." >&2
exit 2
