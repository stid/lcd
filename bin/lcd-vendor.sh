#!/usr/bin/env bash
# lcd-vendor.sh — freeze LCD into a project's own .claude/ so it runs without the plugin,
# and keep that frozen copy updatable.
#
# Usage: lcd-vendor.sh install|update|check [--dry-run] [--force] <project-dir>
#
# The plugin tree this script lives in is the SOURCE: run it from a plugin clone (or the
# tag `/lcd-update` checks out) against the project. Layout written into the project:
#   .claude/lcd/{bin,rules,templates}   engine (bin scripts called by path, rules on demand)
#   .claude/lcd/VERSION, MANIFEST       source version + sha256 of every managed file
#   .claude/skills/lcd-<name>/          skills, renamed (project skills can't use `lcd:`)
#   .claude/commands/lcd-<name>.md      commands, plus lcd-update (templates/vendor/)
#   .claude/agents/lcd-<name>.md        agents (`:` is reserved for plugin agents)
#   .claude/rules/ac-convention.md      path-scoped AC rule, only if the project has none
#   .claude/settings.json               LCD hooks + path-based permissions, merged in
#
# Project-owned files are never touched: artifacts, lcd-conventions.md, other settings keys.
# In CLAUDE.md / AGENTS.md only the LCD pointer tokens (`lcd:triage`, `/lcd:resume`) are
# renamed. `update` refuses when a managed file was edited or deleted locally (named on
# stderr) unless --force; `--dry-run` prints the plan and writes nothing. `check` exits 0
# only when the vendored version equals the source version and nothing drifted.
#
# Unlike the hooks, this is an installer: it fails CLOSED (jq required, bad JSON = error).
set -euo pipefail

src="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "usage: lcd-vendor.sh install|update|check [--dry-run] [--force] <project-dir>" >&2
  exit 2
}

mode="${1:-}"
[[ $# -gt 0 ]] && shift
case "$mode" in install|update|check) ;; *) usage ;; esac
dry=0 force=0 proj=""
for a in "$@"; do
  case "$a" in
    --dry-run) dry=1 ;;
    --force) force=1 ;;
    -*) usage ;;
    *) [[ -z "$proj" ]] || usage; proj="$a" ;;
  esac
done
[[ -n "$proj" ]] || usage

die() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die "jq is required"
[[ -d "$proj" ]] || die "$proj is not a directory"
proj="$(cd "$proj" && pwd -P)"
lcd="$proj/.claude/lcd"

# assert_inside <relpath> — managed paths come from a MANIFEST anyone can commit to, so
# each must stay under .claude/ (no `..`) and never pass through a symlink inside the project.
assert_inside() {
  local rel="$1" cur="$proj" part parts
  [[ "$rel" =~ ^\.claude/[A-Za-z0-9._/-]+$ && "/$rel/" != *"/../"* ]] || die "unsafe managed path: $rel"
  IFS=/ read -ra parts <<<"$rel"
  for part in "${parts[@]}"; do
    cur="$cur/$part"
    [[ ! -L "$cur" ]] || die "refusing to follow symlink: ${cur#"$proj"/}"
  done
}
if [[ -f "$lcd/MANIFEST" ]]; then
  while read -r _ p; do assert_inside "$p"; done < "$lcd/MANIFEST"
fi
new_ver="$(jq -r .version "$src/.claude-plugin/plugin.json")"
new_commit="$(git -C "$src" rev-parse --short HEAD 2>/dev/null || echo unknown)"

hash_of() { shasum -a 256 "$1" | cut -d' ' -f1; }

# manifest_hash <relpath> — hash recorded for a managed file, empty if unmanaged
manifest_hash() {
  [[ -f "$lcd/MANIFEST" ]] || return 0
  awk -v p="$1" '{ h = $1; $1 = ""; sub(/^ +/, ""); if ($0 == p) print h }' "$lcd/MANIFEST"
}

# --- drift: managed files edited or deleted since they were vendored --------------------
drift() {
  [[ -f "$lcd/MANIFEST" ]] || return 0
  local h p
  while read -r h p; do
    if [[ ! -f "$proj/$p" ]]; then echo "deleted: $p"
    elif [[ "$(hash_of "$proj/$p")" != "$h" ]]; then echo "modified: $p"
    fi
  done < "$lcd/MANIFEST"
}

if [[ "$mode" == "check" ]]; then
  [[ -f "$lcd/MANIFEST" ]] || die "$proj is not vendored (no .claude/lcd/MANIFEST)"
  cur="$(sed -n 's/^version: //p' "$lcd/VERSION")"
  d="$(drift)"
  echo "vendored: $cur · source: $new_ver"
  [[ -z "$d" ]] || { echo "local drift:"; sed 's/^/  /' <<<"$d"; }
  if [[ "$cur" == "$new_ver" && -z "$d" ]]; then echo "up to date"; exit 0; fi
  exit 1
fi

if [[ "$mode" == "install" && -f "$lcd/MANIFEST" ]]; then
  die "$proj is already vendored ($(sed -n 's/^version: //p' "$lcd/VERSION")) — use update"
fi
if [[ "$mode" == "update" && ! -f "$lcd/MANIFEST" ]]; then
  die "$proj is not vendored — run install first"
fi

settings="$proj/.claude/settings.json"
for p in .claude/settings.json .claude/lcd/MANIFEST .claude/lcd/VERSION; do assert_inside "$p"; done
if [[ -f "$settings" ]]; then jq -e . "$settings" >/dev/null 2>&1 || die "$settings is not valid JSON"; fi

# --- render the full managed tree into a stage dir ---------------------------------------
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

put() { mkdir -p "$(dirname "$stage/$2")"; cp -p "$1" "$stage/$2"; }

for f in "$src"/bin/*; do
  [[ "$(basename "$f")" == "lcd-vendor.sh" ]] || put "$f" ".claude/lcd/bin/$(basename "$f")"
done
for f in "$src"/rules/*.md; do put "$f" ".claude/lcd/rules/$(basename "$f")"; done
for f in "$src"/docs/*.md; do put "$f" ".claude/lcd/docs/$(basename "$f")"; done
(cd "$src/templates" && find . -type f ! -path './vendor/*') | while read -r f; do
  put "$src/templates/$f" ".claude/lcd/templates/${f#./}"
done
for d in "$src"/skills/*/; do
  n="$(basename "$d")"
  (cd "$d" && find . -type f) | while read -r f; do put "$d$f" ".claude/skills/lcd-$n/${f#./}"; done
done
# vendor.md is plugin-only: it drives this script, which a frozen copy doesn't carry
# (a frozen copy updates through lcd-update instead).
for f in "$src"/commands/*.md; do
  [[ "$(basename "$f")" == "vendor.md" ]] || put "$f" ".claude/commands/lcd-$(basename "$f")"
done
put "$src/templates/vendor/lcd-update.md" ".claude/commands/lcd-update.md"
for f in "$src"/agents/*.md; do put "$f" ".claude/agents/$(basename "$f")"; done

# Rewrite plugin references into project ones. Order matters: specific plugin-root paths
# first, then the namespace, then bare script names (which the plugin puts on PATH).
scripts='parse-acs|audit-crosspath|lcd-doctor|lcd-triage-log|lcd-boundary-check|lcd-session-context|lcd-staleness-check|lcd-hooklib'
(cd "$stage" && find . -type f) | while read -r f; do
  f="$stage/${f#./}"
  extra=()
  [[ "$f" == "$stage/.claude/lcd/bin/"* ]] \
    || extra=(-e "s#(^|[^A-Za-z0-9_./-])(${scripts})\.sh#\1.claude/lcd/bin/\2.sh#g")
  sed -E \
    -e 's#\$\{CLAUDE_PLUGIN_ROOT\}/skills/([a-z-]+)/#.claude/skills/lcd-\1/#g' \
    -e 's#\$\{CLAUDE_PLUGIN_ROOT\}/commands/([a-z-]+)\.md#.claude/commands/lcd-\1.md#g' \
    -e 's#\$\{CLAUDE_PLUGIN_ROOT\}/agents/#.claude/agents/#g' \
    -e 's#"?\$\{CLAUDE_PLUGIN_ROOT\}"?/#.claude/lcd/#g' \
    -e 's#\$\{CLAUDE_PLUGIN_ROOT\}#.claude/lcd#g' \
    -e 's#lcd:lcd-#lcd-#g' \
    -e 's#(^|[^A-Za-z0-9_-])(/?)lcd:([a-z*])#\1\2lcd-\3#g' \
    ${extra[@]+"${extra[@]}"} "$f" > "$f.tmp"
  cat "$f.tmp" > "$f" && rm -f "$f.tmp"
done
for f in "$stage"/.claude/skills/lcd-*/SKILL.md; do
  sed -E 's#^name: ([a-z])#name: lcd-\1#; s#^name: lcd-lcd-#name: lcd-#' "$f" > "$f.tmp"
  cat "$f.tmp" > "$f" && rm -f "$f.tmp"
done

new_manifest="$stage.manifest"
(cd "$stage" && find . -type f | sed 's#^\./##' | sort | while read -r p; do
  echo "$(hash_of "$p") $p"; done) > "$new_manifest"
trap 'rm -rf "$stage" "$new_manifest"' EXIT

# --- plan: added / changed / removed, plus conflicts -------------------------------------
added=() changed=() removed=() conflicts=()
while read -r h p; do
  assert_inside "$p"
  old="$(manifest_hash "$p")"
  if [[ -z "$old" ]]; then
    added+=("$p")
    [[ ! -e "$proj/$p" ]] || conflicts+=("exists unmanaged: $p")
  elif [[ "$old" != "$h" ]]; then
    changed+=("$p")
  fi
done < "$new_manifest"
if [[ -f "$lcd/MANIFEST" ]]; then
  while read -r h p; do
    grep -qxF "$p" <(cut -d' ' -f2- "$new_manifest") || removed+=("$p")
  done < "$lcd/MANIFEST"
fi
while IFS= read -r line; do [[ -z "$line" ]] || conflicts+=("$line"); done <<<"$(drift)"

cur_ver="$( [[ -f "$lcd/VERSION" ]] && sed -n 's/^version: //p' "$lcd/VERSION" || echo none)"

if [[ $dry -eq 1 ]]; then
  echo "LCD $mode (dry run): $cur_ver → $new_ver ($new_commit)"
  for p in "${added[@]+"${added[@]}"}"; do echo "added: $p"; done
  for p in "${changed[@]+"${changed[@]}"}"; do echo "changed: $p"; done
  for p in "${removed[@]+"${removed[@]}"}"; do echo "removed: $p"; done
  if [[ ${#conflicts[@]} -gt 0 ]]; then
    echo "blocked (would need --force):"
    printf '  %s\n' "${conflicts[@]}"
  fi
  if [[ "$cur_ver" != none && -f "$src/CHANGELOG.md" ]]; then
    echo "--- CHANGELOG ($cur_ver → $new_ver) ---"
    awk -v lo="$cur_ver" -v hi="$new_ver" '
      function cmp(a, b,   x, y, i) {
        split(a, x, "."); split(b, y, ".")
        for (i = 1; i <= 3; i++) { if (x[i] + 0 != y[i] + 0) return (x[i] + 0 < y[i] + 0) ? -1 : 1 }
        return 0
      }
      /^## \[/ { v = $2; gsub(/[\[\]]/, "", v); on = (cmp(v, lo) > 0 && cmp(v, hi) <= 0) }
      on' "$src/CHANGELOG.md"
  fi
  exit 0
fi

if [[ ${#conflicts[@]} -gt 0 && $force -eq 0 ]]; then
  echo "error: refusing to $mode — these paths would be overwritten (re-run with --force to accept):" >&2
  printf '  %s\n' "${conflicts[@]}" >&2
  exit 1
fi

# --- apply --------------------------------------------------------------------------------
for p in "${added[@]+"${added[@]}"}" "${changed[@]+"${changed[@]}"}"; do
  mkdir -p "$(dirname "$proj/$p")"
  cp -p "$stage/$p" "$proj/$p"
done
# --force over a locally edited file whose upstream copy didn't change: restore ours
while read -r h p; do
  [[ -f "$proj/$p" && "$(hash_of "$proj/$p")" == "$h" ]] || { mkdir -p "$(dirname "$proj/$p")"; cp -p "$stage/$p" "$proj/$p"; }
done < "$new_manifest"
for p in "${removed[@]+"${removed[@]}"}"; do
  rm -f "$proj/$p"
  rmdir -p "$(dirname "$proj/$p")" 2>/dev/null || true
done
mkdir -p "$lcd"
cp "$new_manifest" "$lcd/MANIFEST"
printf 'version: %s\ncommit: %s\nsource: github.com/stid/lcd\n' "$new_ver" "$new_commit" > "$lcd/VERSION"

# The AC rule is a seed, not managed: onboard rewrites its `paths:` for a non-default artifact
# root, and that copy must survive every update. Written only when the project has none.
acr=".claude/rules/ac-convention.md"
assert_inside "$acr"
[[ -e "$proj/$acr" ]] || { mkdir -p "$proj/.claude/rules"; cp "$stage/.claude/lcd/rules/ac-convention.md" "$proj/$acr"; }

# Hooks + permissions: drop previous LCD hook ENTRIES (a user hook sharing their group stays),
# drop groups and events left empty, then add the source's — idempotent.
hooks="$(jq '(.. | .command? | strings) |= sub("\\$\\{CLAUDE_PLUGIN_ROOT\\}\"/bin/"; "$CLAUDE_PROJECT_DIR\"/.claude/lcd/bin/")' \
  "$src/hooks/hooks.json")"
perms='["Bash(.claude/lcd/bin/audit-crosspath.sh:*)","Bash(.claude/lcd/bin/parse-acs.sh:*)","Bash(.claude/lcd/bin/lcd-doctor.sh:*)","Bash(.claude/lcd/bin/lcd-triage-log.sh:*)"]'
[[ -f "$settings" ]] || echo '{}' > "$settings"
jq --argjson new "$hooks" --argjson perms "$perms" '
  .hooks = ((.hooks // {})
            | with_entries(.value |= (map(.hooks |= map(select((.command // "") | contains(".claude/lcd/bin/") | not)))
                                      | map(select(.hooks | length > 0))))
            | with_entries(select(.value | length > 0)))
  | reduce ($new.hooks | to_entries[]) as $e (.; .hooks[$e.key] = ((.hooks[$e.key] // []) + $e.value))
  | .permissions.allow = (((.permissions.allow // []) | map(select(startswith("Bash(.claude/lcd/bin/") | not))) + $perms)
' "$settings" > "$settings.tmp"
cat "$settings.tmp" > "$settings" && rm -f "$settings.tmp"

for md in "$proj/CLAUDE.md" "$proj/AGENTS.md"; do
  [[ -f "$md" && ! -L "$md" ]] && grep -qE '`lcd:triage`|`/lcd:resume' "$md" || continue
  sed -e 's#`lcd:triage`#`lcd-triage`#g' -e 's#`/lcd:resume#`/lcd-resume#g' "$md" > "$md.tmp"
  cat "$md.tmp" > "$md" && rm -f "$md.tmp"
done

echo "LCD $mode: $cur_ver → $new_ver ($new_commit) · ${#added[@]} added · ${#changed[@]} changed · ${#removed[@]} removed"
[[ -f "$proj/.claude/rules/lcd-conventions.md" ]] || echo "next: project not onboarded yet — run /lcd-onboard"
echo "Disable the lcd plugin (and drop --plugin-dir) for this project, or hooks fire twice."
