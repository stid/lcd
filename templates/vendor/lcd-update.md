---
description: LCD — update this project's frozen (vendored) copy of LCD to a newer release; shows the plan and the CHANGELOG first, never overwrites local edits without asking
argument-hint: "[vX.Y.Z | path-to-lcd-clone]"
---

You are running **LCD update** for a project that carries a frozen copy of LCD in
`.claude/lcd/` (written by `lcd-vendor.sh`, no plugin installed). The update is done by the
**target** release's own `bin/lcd-vendor.sh`, so the new version's rewrite rules apply.

1. **Current version:** read `.claude/lcd/VERSION`. If it's missing, stop: this project isn't
   vendored (install with `lcd-vendor.sh install .` from an LCD clone).
2. **Resolve the source** from `$ARGUMENTS`:
   - an existing directory → use it as the LCD source (a local clone; `git -C <dir> pull`
     is the user's call, don't do it unasked);
   - `vX.Y.Z` → that tag; empty → the latest release tag:
     `git ls-remote --tags --refs https://github.com/stid/lcd 'v*' | sed 's#.*/##' | sort -V | tail -1`.
     Shallow-clone it into a fresh temp dir:
     `git clone --quiet --depth 1 --branch <tag> https://github.com/stid/lcd "$(mktemp -d)/lcd"`.
   If the network or GitHub is unreachable, say so and offer the local-clone form instead.
   If `<source>/bin/lcd-vendor.sh` doesn't exist, stop: that release predates vendoring
   (added in 0.20.0) and can't update a frozen copy.
3. **Preview:** run `<source>/bin/lcd-vendor.sh update --dry-run .` and show the user its output
   as is: the from → to versions, the added / changed / removed files, any `blocked` paths, and
   the CHANGELOG sections in between. If the versions are equal and nothing is listed, report
   "already up to date" and stop.
4. **Confirm** with `AskUserQuestion`: apply, or cancel. If paths are `blocked` (edited or
   deleted locally), explain that applying overwrites them and offer: apply with `--force`,
   or cancel so the user can keep their edits (suggest upstreaming them as a PR on
   `github.com/stid/lcd`).
5. **Apply:** `<source>/bin/lcd-vendor.sh update [--force] .` and show its summary line. Then run
   `.claude/lcd/bin/lcd-doctor.sh` and show the result.
   **CI gate copies:** if `.github/workflows/lcd-audit.yml` exists, the gate runs its own copies
   at `<artifact-root>/ci/{parse-acs,audit-crosspath}.sh` (artifact root from
   `.claude/rules/lcd-conventions.md`), which the update doesn't manage. `diff` each against
   `.claude/lcd/bin/`; if they differ, show the diff and offer to copy the new ones over.
6. Remove the temp clone if you made one. Show `git status`. **Don't commit or push** — the user
   reviews the diff of `.claude/` first.
