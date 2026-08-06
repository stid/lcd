---
description: LCD Deep lane phase 6 — run when the suite is green, before opening a PR; verifies every (AC × surface) has a handler AND a passing test
argument-hint: "<slug>"
---

You are running **Deep-lane phase 6 of Lean Context Development**. This phase is the PR-creation gate: every cross-path AC must be covered before a PR can be opened. See the `lcd:triage` skill for orchestration.

Target slug: `$ARGUMENTS`

## Setup

**Resolve the artifact root** from `.claude/rules/lcd-conventions.md` (`artifact-root`, default `docs/lcd`). The audit script (`audit-crosspath.sh`, on PATH via the plugin's `bin/`) reads `LCD_SPECS_DIR` = `<artifact-root>/work`.

## What to do

1. **Refuse if `spec.md` or `plan.md` is missing** under `<artifact-root>/work/<slug>/`. Tell the user which phase is missing. **Exception — Standard-lane items** (a JOURNAL with inline ACs, no spec/plan by design): don't refuse and don't run the script — its handler checks need plan.md's cross-path matrix, which Standard doesn't have. The Standard audit is the test-presence half only: for each inline `**AC-N** (surfaces: …)` in the JOURNAL, grep the repo for a passing test carrying the literal `AC-N (SURFACE)`; all present + the suite green = PASS. Record the result in the JOURNAL LOG (no `audit.md` file), then continue at step 4's closeout with `audit: PASS (test-presence)`.

2. **Run the audit script from the project root**, pointing it at the resolved work dir:

   ```bash
   LCD_SPECS_DIR="<artifact-root>/work" audit-crosspath.sh <slug>
   ```

   It reads spec.md ACs (via `parse-acs.sh`), plan.md's Cross-path matrix for the path per (AC × surface), checks each handler (`<file>:<token>` → file exists and contains the token; bare `<file>` → file exists), and greps the repo for a test carrying the literal `AC-N (SURFACE)`. It emits a markdown table and exits non-zero if any row is not `OK`.

3. **Save the audit output** to `<artifact-root>/work/<slug>/audit.md` using `${CLAUDE_PLUGIN_ROOT}/templates/audit.md`. Fill the metadata (slug, run timestamp, PASS/BLOCKED) and paste the table from step 2.

4. **If the script exited 0 (all OK):** set `Result: PASS`; tell the user "Audit PASSED. Safe to open PR."; suggest committing anything pending and running the full gate before `gh pr create`. Mark `audit.md ✅` in the JOURNAL pipeline tracker.

   Then, **if the conventions block has `closeout-evaluator: on`**, dispatch the plugin's
   `lcd-evaluator` agent (read-only, fresh context) with the slug, the artifact root, the ACs,
   and the baseline..HEAD diff range — **before** the closeout line and the reconcile fold, so
   a challenged verdict lands before the closeout is logged and before the ACs are folded into
   `SPEC.md`. Record its result in the JOURNAL LOG — `evaluator: stands` or
   `evaluator: challenged (<n> findings)` plus the findings verbatim — and present the findings
   to the user **before** suggesting `gh pr create`. The verdict is advisory (it doesn't reopen
   the audit result), but on `challenged` the sane order is fix, re-audit, and only then close
   out. Skip when the key is `off` or absent.

   Then **append the work-item's closeout line** to `<artifact-root>/triage-log.md` (contract in the `lcd:triage` skill, "Closeout" section):

   ```
   <date> · <slug> · closeout · <Lane> · audit: PASS (first run | run N) · re-routes: <n> · red-green iters: <n> · interventions: <n>
   ```

   Pull lane / re-routes / iterations / interventions from the JOURNAL (NOW.Lane, LOG entries, the red-green loop's iteration note); `run N` = how many audit runs this slug needed to reach PASS.

   Then, **if `.claude/rules/lcd-conventions.md` has `living-spec: on`**, invoke
   `lcd:reconcile <slug>` to fold this work-item's ACs into `<artifact-root>/SPEC.md` (the
   living current-state index). It's a no-op when the flag is off, so this step is safe to run
   unconditionally — but only the PASS branch reaches it.

5. **If the script exited non-zero (any MISSING / BLOCKED):** set `Result: BLOCKED`; print the table with a clear "PR creation blocked" message; for each non-OK row explain the fix:
   - `MISSING-HANDLER` → plan-declared path doesn't resolve. Wire the handler, or fix the plan's path cell. For `EVAL`, curate the golden-dataset file at the declared path.
   - `MISSING-TEST` → handler resolves but no test carries `AC-N (SURFACE)`. Re-run `/lcd:test-gen` or rename an existing test to match exactly.
   - `MISSING` → both absent; the surface was never implemented.
   - `BLOCKED` → plan.md lacks a matrix row for this (AC, surface); update the plan first.
   - Don't auto-fix — phase 6 is read-only; the fix path is back to phase 4 (tests) or phase 5 (implementation).

## What NOT to do

- Don't edit source or tests — this phase is verification only.
- Don't suggest `gh pr create` while any row is not OK.
- Don't modify the spec to make a failing row pass — that silences the symptom. Update the plan or implementation.

## Quality gate before declaring done

- `audit.md` exists under `<artifact-root>/work/<slug>/`.
- `Result:` accurately reflects PASS or BLOCKED.
- If BLOCKED: the user knows which rows need attention and the fix paths.
- If PASS: the user knows the next step is run-gate then `gh pr create`.

## Common false-positive sources (and the fix)

- **Handler exists but the plan's path cell is wrong** (wrong file, or `:token` not literally present). Fix the matrix row, re-run.
- **Test-name typo.** Grep the repo for the AC ID; make the literal read exactly `AC-N (SURFACE)`.
- **Token mismatch.** The audit greps the literal token from the path cell. If plan says `:/api/version` but code registers `/api/v1/version`, fix one to match.
