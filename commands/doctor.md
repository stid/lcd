---
description: LCD — run after onboarding, after hand-editing lcd-conventions.md, or when the suite misbehaves; validates the project's LCD setup (machine block, artifacts, pointers)
---

You are running **LCD doctor** — the health check for a project's LCD setup. It turns the
"sanity checks before trusting this file" checklist from the conventions template into an
executable gate. Run it after onboarding, after hand-editing `.claude/rules/lcd-conventions.md`,
or whenever the suite misbehaves (tests not collected, red-green loop hanging, audit not finding
artifacts).

## What to do

1. **Run the script** (ships in the plugin's `bin/`, on PATH while the plugin is enabled):

   ```bash
   lcd-doctor.sh
   ```

   It prints one `OK | WARN | FAIL` line per check and exits non-zero if anything FAILs.

2. **Interpret the result for the user:**
   - **All OK** → say so in one line. Done.
   - **WARNs only** → list them with a one-line consequence each (e.g. a missing MAP means cold
     starts lose guardrails). Offer to fix the cheap ones now; don't insist.
   - **Any FAIL** → these break the suite. Explain each in plain terms and offer the fix:
     - missing/placeholder machine-block keys, or a missing conventions file → re-run
       `/lcd:onboard` (retrofit mode re-detects and fills the block in place).
     - watch-mode test commands (`vitest` without `run`, `jest` without `--watchAll=false`) →
       edit the key to the non-watch form; this is what hangs the red-green loop.
     - missing `ac-convention` override on a non-default artifact root → re-run
       `/lcd:onboard` (it writes `.claude/rules/ac-convention.md` with the right globs).

3. **Fix only on approval**, then re-run the script to confirm it goes green.

## What NOT to do

- Don't rewrite `lcd-conventions.md` wholesale — fix the specific keys the doctor flagged
  (per the `refinement-protocol` rule), or defer to a `/lcd:onboard` retrofit.
- Don't silence a FAIL by deleting the check's subject (e.g. removing the artifact-root key).
