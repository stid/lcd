---
description: LCD — freeze LCD into this project's own .claude/ so contributors get it without the plugin, or update/check an existing frozen copy from this plugin version
argument-hint: "[install | update | check]"
---

You are running **LCD vendor**: it writes (or refreshes) a frozen copy of LCD inside the current
project, using this installed plugin as the source. The work is done by this plugin's own
`${CLAUDE_PLUGIN_ROOT}/bin/lcd-vendor.sh`, called by path, not by name: with more than one LCD
copy loaded, the name on PATH can resolve to a different version. See the README's "Vendoring" section.

1. **Mode:** `$ARGUMENTS` if given (`install`, `update` or `check`); otherwise `update` when
   `.claude/lcd/MANIFEST` exists and `install` when it doesn't.
2. **check:** run `"${CLAUDE_PLUGIN_ROOT}/bin/lcd-vendor.sh" check .`, show the output as is, and stop.
3. **Preview:** run `"${CLAUDE_PLUGIN_ROOT}/bin/lcd-vendor.sh" <mode> --dry-run .` and show its output: the from → to
   versions, the added / changed / removed files, any `blocked` paths, and (on update) the
   CHANGELOG sections in between. On update, if the versions are equal and nothing is listed,
   report "already up to date" and stop.
4. **Confirm** with `AskUserQuestion`. On install, offer:
   - **Install and disable the plugin for this project (recommended):** without it, a session
     with the plugin enabled runs every hook twice and lists both `lcd:x` and `lcd-x`.
   - **Install only.**
   - **Cancel.**

   If paths are `blocked` (edited or deleted locally, or present but unmanaged), explain that
   applying overwrites them and offer `--force` or cancel.
5. **Apply:** `"${CLAUDE_PLUGIN_ROOT}/bin/lcd-vendor.sh" <mode> [--force] .` and show its summary line. If the user chose to
   disable the plugin, merge `"enabledPlugins": {"lcd@lcd": false}` into `.claude/settings.json`,
   keeping every other key (re-read it after the script wrote it; validate it parses). Then run
   `.claude/lcd/bin/lcd-doctor.sh` and show the result.
6. Show `git status`. **Don't commit or push**; the user reviews the diff of `.claude/` first.
   Tell them: commit `.claude/` (it must not be gitignored) so cloning the project carries LCD.
   Later updates run from inside the frozen copy with `/lcd-update`, since the plugin is off there.
