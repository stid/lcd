#!/usr/bin/env bash
# Tests for bin/lcd-vendor.sh — freezing LCD into a project's own .claude/ and updating it.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

command -v jq >/dev/null 2>&1 || fail "jq is required for these tests"

init_tmpdir
repo="$(cd "$PLUGIN_BIN/.." && pwd)"
ver="$(jq -r .version "$repo/.claude-plugin/plugin.json")"

# make_source <dir> — a copy of the plugin tree the vendor script can run from
make_source() {
  mkdir -p "$1"
  cp -R "$repo/bin" "$repo/skills" "$repo/commands" "$repo/agents" "$repo/rules" \
    "$repo/templates" "$repo/hooks" "$repo/.claude-plugin" "$repo/CHANGELOG.md" "$1/"
}

# make_project <dir> — an onboarded project with its own settings, pointer and conventions
make_project() {
  mkdir -p "$1/.claude/rules" "$1/docs/lcd"
  printf 'artifact-root: docs/lcd\n' > "$1/.claude/rules/lcd-conventions.md"
  cat > "$1/.claude/settings.json" <<'EOF'
{"model": "keep-me", "permissions": {"allow": ["Bash(npm test)"]},
 "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "echo mine"}]}]}}
EOF
  cat > "$1/CLAUDE.md" <<'EOF'
# Project
Own text that mentions nothing.

## Lean Context Development (LCD)
Non-trivial new work → invoke
`lcd:triage`, which picks a lane.
Resume any work-item after a context reset: `/lcd:resume <slug>`.
EOF
}

# snapshot <dir> — hash of every file under it (detects any write)
snapshot() {
  (cd "$1" && find . -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256)
}

vendor() { bash "$src/bin/lcd-vendor.sh" "$@"; }

src="$tmp/src"; make_source "$src"
proj="$tmp/proj"; make_project "$proj"
conv_before="$(shasum -a 256 < "$proj/.claude/rules/lcd-conventions.md")"

# --- usage ------------------------------------------------------------------
vendor bogus "$proj" >/dev/null 2>&1; assert_exit 2 $? "unknown mode → usage error"
vendor install >/dev/null 2>&1; assert_exit 2 $? "missing project → usage error"

# --- AC-1 (CLI): install writes the managed tree, prefixed, no plugin refs ----
out="$(vendor install "$proj" 2>&1)"; code=$?
assert_exit 0 "$code" "AC-1 (CLI) install succeeds"
for d in bin rules templates; do
  [[ -d "$proj/.claude/lcd/$d" ]] || fail "AC-1 (CLI): .claude/lcd/$d missing"
done
assert_contains "$(cat "$proj/.claude/lcd/VERSION")" "version: $ver" "AC-1 (CLI) VERSION stamp"
[[ -s "$proj/.claude/lcd/MANIFEST" ]] || fail "AC-1 (CLI): MANIFEST empty"
for f in skills/lcd-triage/SKILL.md skills/lcd-triage/references/lanes.md \
         commands/lcd-audit.md commands/lcd-doctor.md commands/lcd-resume.md \
         commands/lcd-update.md agents/lcd-evaluator.md; do
  [[ -f "$proj/.claude/$f" ]] || fail "AC-1 (CLI): .claude/$f missing"
done
[[ ! -e "$proj/.claude/lcd/bin/lcd-vendor.sh" ]] || fail "AC-1 (CLI): vendor script itself was vendored"
assert_contains "$(cat "$proj/.claude/skills/lcd-triage/SKILL.md")" "name: lcd-triage" "AC-1 (CLI) skill renamed"
left="$(grep -rl 'CLAUDE_PLUGIN_ROOT' "$proj/.claude" || true)"
[[ -z "$left" ]] || fail "AC-1 (CLI): CLAUDE_PLUGIN_ROOT left in: $left"
left="$(grep -rlE '(^|[^A-Za-z0-9_-])/?lcd:[a-z]' "$proj/.claude" || true)"
[[ -z "$left" ]] || fail "AC-1 (CLI): plugin-namespaced lcd: refs left in: $left"
assert_contains "$(cat "$proj/.claude/commands/lcd-audit.md")" ".claude/lcd/bin/audit-crosspath.sh" \
  "AC-1 (CLI) bare script names become vendored paths"
cmds="$(jq -r '.hooks[][].hooks[].command' "$proj/.claude/settings.json" | grep 'lcd/bin')"
[[ "$(wc -l <<<"$cmds")" -eq 3 ]] || fail "AC-1 (CLI): expected 3 LCD hook commands, got: $cmds"
while IFS= read -r c; do
  p="${c//\"\$CLAUDE_PROJECT_DIR\"/$proj}"
  [[ -x "$p" ]] || fail "AC-1 (CLI): hook command not executable: $c"
done <<<"$cmds"

# --- AC-2 (CLI): settings merge, pointer rewrite, refusals --------------------
s="$proj/.claude/settings.json"
[[ "$(jq -r .model "$s")" == "keep-me" ]] || fail "AC-2 (CLI): model key lost"
jq -e '.permissions.allow | index("Bash(npm test)")' "$s" >/dev/null || fail "AC-2 (CLI): own permission lost"
jq -e '[.hooks.Stop[].hooks[].command] | index("echo mine")' "$s" >/dev/null || fail "AC-2 (CLI): own hook lost"
jq -e '.permissions.allow | index("Bash(.claude/lcd/bin/audit-crosspath.sh:*)")' "$s" >/dev/null \
  || fail "AC-2 (CLI): path-based permission missing"
md="$(cat "$proj/CLAUDE.md")"
assert_contains "$md" '`lcd-triage`' "AC-2 (CLI) pointer triage token rewritten"
assert_contains "$md" '`/lcd-resume <slug>`' "AC-2 (CLI) pointer resume token rewritten"
assert_contains "$md" "Own text that mentions nothing." "AC-2 (CLI) own CLAUDE.md text kept"
[[ -f "$proj/.claude/rules/ac-convention.md" ]] || fail "AC-2 (CLI): ac-convention rule not installed"
[[ "$(shasum -a 256 < "$proj/.claude/rules/lcd-conventions.md")" == "$conv_before" ]] \
  || fail "AC-2 (CLI): lcd-conventions.md was modified"
before="$(snapshot "$proj")"
out="$(vendor install "$proj" 2>&1)"; code=$?
[[ $code -ne 0 ]] || fail "AC-2 (CLI): second install should refuse"
assert_contains "$out" "already vendored" "AC-2 (CLI) second install message"
[[ "$(snapshot "$proj")" == "$before" ]] || fail "AC-2 (CLI): refused install wrote files"

p2="$tmp/p2"; make_project "$p2"
mkdir -p "$p2/.claude/skills/lcd-triage"; echo mine > "$p2/.claude/skills/lcd-triage/SKILL.md"
printf -- '---\npaths: ["x/**"]\n---\nmine\n' > "$p2/.claude/rules/ac-convention.md"
out="$(vendor install "$p2" 2>&1)"; code=$?
[[ $code -ne 0 ]] || fail "AC-2 (CLI): install over an unmanaged lcd-triage should refuse"
assert_contains "$out" "skills/lcd-triage" "AC-2 (CLI) conflict named"
[[ ! -e "$p2/.claude/lcd" ]] || fail "AC-2 (CLI): refused install created .claude/lcd"
rm -rf "$p2/.claude/skills"
vendor install "$p2" >/dev/null 2>&1 || fail "AC-2 (CLI): install after clearing conflict failed"
assert_contains "$(cat "$p2/.claude/rules/ac-convention.md")" "mine" "AC-2 (CLI) project ac-convention untouched"

# --- AC-3 (CLI): update — idempotent, then applies upstream changes ----------
before="$(snapshot "$proj")"
vendor update "$proj" >/dev/null 2>&1; assert_exit 0 $? "AC-3 (CLI) no-op update succeeds"
[[ "$(snapshot "$proj")" == "$before" ]] || fail "AC-3 (CLI): no-op update changed files"

src2="$tmp/src2"; make_source "$src2"
echo "UPSTREAM-CHANGE-MARKER" >> "$src2/skills/triage/SKILL.md"
rm "$src2/commands/tidy.md"
printf -- '---\ndescription: new\n---\nnew command\n' > "$src2/commands/newcmd.md"
jq '.version = "9.9.9"' "$src2/.claude-plugin/plugin.json" > "$tmp/pj" && cat "$tmp/pj" > "$src2/.claude-plugin/plugin.json"
{ printf '# Changelog\n\n## [9.9.9] — test\n\n- CHANGELOG-BETWEEN-MARKER\n\n'; tail -n +2 "$repo/CHANGELOG.md"; } > "$src2/CHANGELOG.md"
vendor2() { bash "$src2/bin/lcd-vendor.sh" "$@"; }

cp -R "$proj" "$tmp/proj-dry"
# --- AC-5 (CLI): dry-run reports the plan and writes nothing -----------------
before="$(snapshot "$tmp/proj-dry")"
out="$(vendor2 update --dry-run "$tmp/proj-dry" 2>&1)"; code=$?
assert_exit 0 "$code" "AC-5 (CLI) dry-run succeeds"
assert_contains "$out" "$ver → 9.9.9" "AC-5 (CLI) version from→to"
assert_contains "$out" "changed: .claude/skills/lcd-triage/SKILL.md" "AC-5 (CLI) changed file listed"
assert_contains "$out" "removed: .claude/commands/lcd-tidy.md" "AC-5 (CLI) removed file listed"
assert_contains "$out" "added: .claude/commands/lcd-newcmd.md" "AC-5 (CLI) added file listed"
assert_contains "$out" "CHANGELOG-BETWEEN-MARKER" "AC-5 (CLI) changelog between versions"
assert_not_contains "$out" "## [$ver]" "AC-5 (CLI) current version's changelog excluded"
[[ "$(snapshot "$tmp/proj-dry")" == "$before" ]] || fail "AC-5 (CLI): dry-run wrote files"

cp -R "$proj" "$tmp/proj-mod"
out="$(vendor2 update "$proj" 2>&1)"; code=$?
assert_exit 0 "$code" "AC-3 (CLI) update to newer source succeeds"
assert_contains "$(cat "$proj/.claude/skills/lcd-triage/SKILL.md")" "UPSTREAM-CHANGE-MARKER" "AC-3 (CLI) changed file replaced"
[[ ! -e "$proj/.claude/commands/lcd-tidy.md" ]] || fail "AC-3 (CLI): upstream-removed file kept"
[[ -f "$proj/.claude/commands/lcd-newcmd.md" ]] || fail "AC-3 (CLI): upstream-added file missing"
assert_contains "$(cat "$proj/.claude/lcd/VERSION")" "version: 9.9.9" "AC-3 (CLI) VERSION rewritten"
assert_not_contains "$(cat "$proj/.claude/lcd/MANIFEST")" "lcd-tidy.md" "AC-3 (CLI) MANIFEST drops removed file"
n="$(jq '[.hooks[][].hooks[].command | select(contains("lcd-session-context"))] | length' "$proj/.claude/settings.json")"
[[ "$n" -eq 1 ]] || fail "AC-3 (CLI): LCD hooks duplicated on update ($n)"

# --- AC-4 (CLI): local edits block the update unless --force ------------------
pm="$tmp/proj-mod"
echo "LOCAL-EDIT" >> "$pm/.claude/skills/lcd-triage/SKILL.md"
rm "$pm/.claude/commands/lcd-audit.md"
before="$(snapshot "$pm")"
out="$(vendor2 update "$pm" 2>&1)"; code=$?
[[ $code -ne 0 ]] || fail "AC-4 (CLI): update over local edits should refuse"
assert_contains "$out" ".claude/skills/lcd-triage/SKILL.md" "AC-4 (CLI) modified file named"
assert_contains "$out" ".claude/commands/lcd-audit.md" "AC-4 (CLI) deleted file named"
[[ "$(snapshot "$pm")" == "$before" ]] || fail "AC-4 (CLI): refused update wrote files"
vendor2 update --force "$pm" >/dev/null 2>&1; assert_exit 0 $? "AC-4 (CLI) --force applies"
assert_contains "$(cat "$pm/.claude/lcd/VERSION")" "version: 9.9.9" "AC-4 (CLI) forced update rewrote VERSION"

# --- AC-6 (CLI): check reports version and drift ------------------------------
out="$(vendor2 check "$proj" 2>&1)"; code=$?
assert_exit 0 "$code" "AC-6 (CLI) check clean + current"
assert_contains "$out" "9.9.9" "AC-6 (CLI) check names version"
out="$(vendor check "$proj" 2>&1)"; code=$?
assert_exit 1 "$code" "AC-6 (CLI) check against a different source version"
echo "LOCAL" >> "$proj/.claude/agents/lcd-evaluator.md"
out="$(vendor2 check "$proj" 2>&1)"; code=$?
assert_exit 1 "$code" "AC-6 (CLI) check with drift"
assert_contains "$out" ".claude/agents/lcd-evaluator.md" "AC-6 (CLI) drifted file listed"
vendor2 check "$tmp/nope" >/dev/null 2>&1; [[ $? -ne 0 ]] || fail "AC-6 (CLI): check on non-vendored project should fail"

# --- AC-4 (CLI): a crafted MANIFEST or symlink can't reach outside the project ---------
p3="$tmp/p3"; make_project "$p3"; vendor install "$p3" >/dev/null 2>&1 || fail "p3 install"
echo keep > "$tmp/victim"
h="$(shasum -a 256 < "$tmp/victim" | cut -d' ' -f1)"
echo "$h ../victim" >> "$p3/.claude/lcd/MANIFEST"
vendor2 update --force "$p3" >/dev/null 2>&1; [[ $? -ne 0 ]] || fail "AC-4 (CLI): traversal MANIFEST entry accepted"
[[ -f "$tmp/victim" ]] || fail "AC-4 (CLI): file outside the project was deleted"

p4="$tmp/p4"; make_project "$p4"
echo '{"outside": true}' > "$tmp/global.json"
rm "$p4/.claude/settings.json"; ln -s "$tmp/global.json" "$p4/.claude/settings.json"
out="$(vendor install "$p4" 2>&1)"; [[ $? -ne 0 ]] || fail "AC-4 (CLI): symlinked settings.json accepted"
assert_contains "$out" "symlink" "AC-4 (CLI) symlink refusal message"
[[ "$(cat "$tmp/global.json")" == '{"outside": true}' ]] || fail "AC-4 (CLI): wrote through settings symlink"

p5="$tmp/p5"; make_project "$p5"; mkdir -p "$tmp/elsewhere"; ln -s "$tmp/elsewhere" "$p5/.claude/skills"
vendor install "$p5" >/dev/null 2>&1; [[ $? -ne 0 ]] || fail "AC-4 (CLI): symlinked .claude/skills accepted"
[[ -z "$(ls -A "$tmp/elsewhere")" ]] || fail "AC-4 (CLI): wrote through a symlinked directory"

echo "ok"
