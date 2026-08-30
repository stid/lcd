#!/usr/bin/env bash
# lcd-hooklib.sh — shared helpers for LCD's hook scripts. Source, don't execute.
#
# Design rule: hooks FAIL OPEN. A guardrail that breaks normal editing is worse than no
# guardrail — any missing dependency, unparseable input, or un-onboarded project must result
# in "allow" (exit 0, no output), never a block.

# lcd_json_field <json> <dot.path> — extract a string field; empty on any failure.
# Tries jq, python3, node in that order (no hard dependency on any one of them).
lcd_json_field() {
  local json="$1" path="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r ".${path} // empty" 2>/dev/null
    return
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$json" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    for k in sys.argv[1].split("."):
        d = d[k]
    print(d if isinstance(d, str) else json.dumps(d))
except Exception:
    pass' "$path" 2>/dev/null
    return
  fi
  if command -v node >/dev/null 2>&1; then
    printf '%s' "$json" | node -e '
let s = ""; process.stdin.on("data", c => s += c).on("end", () => {
  try {
    let d = JSON.parse(s);
    for (const k of process.argv[1].split(".")) d = d[k];
    if (d !== undefined && d !== null)
      process.stdout.write(typeof d === "string" ? d : JSON.stringify(d));
  } catch {}
});' "$path" 2>/dev/null
    return
  fi
  printf ''
}

# lcd_json_escape <string> — escape for embedding inside a JSON string literal.
lcd_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# lcd_resolve_project — set LCD_PROJ (project dir) and LCD_ROOT (artifact root, relative).
# Returns 1 if the project is not LCD-onboarded.
lcd_resolve_project() {
  LCD_PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
  local conv="$LCD_PROJ/.claude/rules/lcd-conventions.md"
  [[ -f "$conv" ]] || return 1
  LCD_ROOT="$(sed -n 's/^artifact-root:[[:space:]]*//p' "$conv" | head -1)"
  LCD_ROOT="${LCD_ROOT%/}"
  [[ -n "$LCD_ROOT" && "$LCD_ROOT" != *"<"* ]] || LCD_ROOT="docs/lcd"
  return 0
}

# lcd_journal_field <journal> <Field> — extract a `- **Field:** value` line's value
# (first whitespace-delimited token for Branch; the full remainder otherwise).
lcd_journal_field() {
  local j="$1" field="$2" line
  line="$(grep -m1 -F "**${field}:**" "$j" 2>/dev/null || true)"
  [[ -n "$line" ]] || return 0
  line="${line#*\*\*${field}:\*\* }"
  printf '%s' "$line"
}

# lcd_active_journals — print JOURNAL paths of work-items "active" on the current branch:
# the JOURNAL's **Branch:** matches `git rev-parse --abbrev-ref HEAD` AND the resume block
# still has at least one unchecked STEP (`- [ ]`). Done/abandoned items never match.
lcd_active_journals() {
  local branch j bval
  # symbolic-ref first: it also resolves an unborn branch (fresh repo, no commits yet)
  branch="$(git -C "$LCD_PROJ" symbolic-ref --short -q HEAD 2>/dev/null \
    || git -C "$LCD_PROJ" rev-parse --abbrev-ref HEAD 2>/dev/null)" || return 0
  [[ -n "$branch" ]] || return 0
  for j in "$LCD_PROJ/$LCD_ROOT"/work/*/JOURNAL.md; do
    [[ -f "$j" ]] || continue
    bval="$(lcd_journal_field "$j" Branch)"
    bval="${bval%% *}"
    [[ "$bval" == "$branch" ]] || continue
    grep -q -- '- \[ \]' "$j" || continue
    printf '%s\n' "$j"
  done
}

# lcd_expand_braces <entry> — brace-expand a boundary entry: print one line per
# alternative of every `{a,b,…}` group (recursive, so nested/multiple groups work).
# `case` patterns honor `*` globs but NEVER brace-expand, so an unexpanded `{a,b}`
# entry can match nothing — silently denying every edit it was meant to allow.
# Entries without braces pass through unchanged.
lcd_expand_braces() {
  local e="$1"
  if [[ "$e" == *"{"*"}"* ]]; then
    local pre="${e%%\{*}" rest="${e#*\{}"
    local body="${rest%%\}*}" post="${rest#*\}}"
    local alt IFS=','
    for alt in $body; do
      lcd_expand_braces "$pre$alt$post"
    done
  else
    printf '%s\n' "$e"
  fi
}

# lcd_journal_boundary <journal> — print the EDIT BOUNDARY entries, one per line,
# backticks/bullets stripped. Placeholder entries (containing `<`) are skipped.
#
# One bullet may carry more than one path (`- a.md, b.md`) or a trailing note
# (`- a.md (deleted)`) — humans write boundaries that way, and treating the whole bullet
# as one path silently denies every edit it lists. So: split on commas, drop a trailing
# parenthesised note. A brace glob (`{src,lib}/**`) keeps its commas — there they are
# pattern, not separator — and `(group)` path segments are untouched because a note is
# only recognised after whitespace.
lcd_journal_boundary() {
  local j="$1"
  awk '/^## EDIT BOUNDARY/{f=1; next} /^## /{f=0} /<!-- \/lcd-resume -->/{f=0} f' "$j" \
    | sed -n 's/^- *//p' \
    | tr -d '`' \
    | awk '
        {
          n = (index($0, "{") > 0) ? 0 : split($0, part, /,[[:space:]]*/)
          if (n == 0) { n = 1; part[1] = $0 }
          for (i = 1; i <= n; i++) {
            e = part[i]
            sub(/[[:space:]]+\(.*\)[[:space:]]*$/, "", e)
            sub(/^[[:space:]]+/, "", e); sub(/[[:space:]]+$/, "", e)
            if (e != "" && index(e, "<") == 0) print e
          }
        }' || true
}
