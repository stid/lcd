---
description: LCD Deep lane phase 6 — run when the suite is green, before opening a PR; verifies every (AC × surface) has a handler AND a passing test
argument-hint: "<slug>"
---

You are running **the LCD audit** — the PR-creation gate. For the Deep lane this is phase 6 (every cross-path AC covered by a handler AND a test); for a Standard-lane item with inline ACs it is the test-presence half only. See the `lcd:triage` skill for orchestration.

Target slug: `$ARGUMENTS`

## Setup

**Resolve the artifact root** from `.claude/rules/lcd-conventions.md` (`artifact-root`, default `docs/lcd`). The audit script (`audit-crosspath.sh`, on PATH via the plugin's `bin/`) reads `LCD_SPECS_DIR` = `<artifact-root>/work`.

**Pick the lane's path:** `spec.md` + `plan.md` present under `<artifact-root>/work/<slug>/` → Deep lane below. A JOURNAL with inline ACs and no spec/plan (by design) → Standard lane. Neither → refuse and tell the user which phase is missing (`/lcd:specify` / `/lcd:plan`), or that this work-item declared no surface (nothing to audit).

## Standard lane (test-presence audit)

Don't run the script — its handler checks need plan.md's cross-path matrix, which Standard doesn't have.

1. For each inline `**AC-N** (surfaces: …)` in the JOURNAL, grep the repo for a test carrying the literal `AC-N (SURFACE)` (one per declared surface). Then run the full suite.
2. **All tokens present + suite green → PASS.** Record `audit: PASS (test-presence)` in the JOURNAL LOG (no `audit.md` file is written), then continue at **On PASS** below.
3. **Otherwise → BLOCKED.** Name each AC × surface whose token has no test (the fix: write a test, or rename an existing one to carry the exact literal) and any failing test (the fix: back to the build loop). Record `audit: BLOCKED (test-presence): <reason>` in the JOURNAL LOG and stop — a blocked audit gets no closeout line.

## Deep lane

1. **Run the audit script from the project root**, pointing it at the resolved work dir:

   ```bash
   LCD_SPECS_DIR="<artifact-root>/work" audit-crosspath.sh <slug>
   ```

   It reads spec.md ACs (via `parse-acs.sh`), plan.md's Cross-path matrix for the path per (AC × surface), checks each handler (`<file>:<token>` → file exists and contains the token; bare `<file>` → file exists), and greps for a test carrying the literal `AC-N (SURFACE)` — inside the plan's `**Test scope:**` paths when declared (recommended: a stale literal left by another work-item can then never satisfy the gate), else repo-wide. It emits a markdown table and exits non-zero if any row is not `OK`.

2. **Save the audit output** to `<artifact-root>/work/<slug>/audit.md` using `${CLAUDE_PLUGIN_ROOT}/templates/audit.md`. Fill the metadata (slug, run timestamp, PASS/BLOCKED) and paste the table from step 1.

3. **If the script exited 0 (all OK):** set `Result: PASS`; tell the user "Audit PASSED. Safe to open PR."; mark `audit.md ✅` in the JOURNAL pipeline tracker; continue at **On PASS** below.

4. **If the script exited non-zero (any MISSING / BLOCKED):** set `Result: BLOCKED`; print the table with a clear "PR creation blocked" message; for each non-OK row explain the fix:
   - `MISSING-HANDLER` → plan-declared path doesn't resolve. Wire the handler, or fix the plan's path cell. For `EVAL`, curate the golden-dataset file at the declared path.
   - `MISSING-TEST` → handler resolves but no test carries `AC-N (SURFACE)`. Re-run `/lcd:test-gen` or rename an existing test to match exactly.
   - `MISSING` → both absent; the surface was never implemented.
   - `BLOCKED` → plan.md lacks a matrix row for this (AC, surface); update the plan first.
   - Don't auto-fix — the audit is read-only; the fix path is back to phase 4 (tests) or phase 5 (implementation).

## On PASS (both lanes)

Read `${CLAUDE_PLUGIN_ROOT}/skills/triage/references/closeout.md` and run its ONE closeout
action: the `lcd-triage-log.sh closeout` line (audit result `PASS (first run)` / `PASS (run N)` /
`PASS (test-presence)`; lane, re-routes, interventions from the JOURNAL; `--iters` optional) —
with the `lcd-evaluator` dispatch folded in before the append (when `closeout-evaluator: on`;
findings to the JOURNAL LOG and the user before any PR suggestion) and `lcd:reconcile <slug>`
after it (when `living-spec: on`).

Then suggest committing anything pending and running the full gate before `gh pr create`.

## What NOT to do

- Don't edit source or tests — the audit is verification only.
- Don't suggest `gh pr create` while any row is not OK.
- Don't modify the spec to make a failing row pass — that silences the symptom. Update the plan or implementation.

## Quality gate before declaring done

- Deep: `audit.md` exists under `<artifact-root>/work/<slug>/` with `Result:` accurately PASS or BLOCKED. Standard: the JOURNAL LOG carries the test-presence result.
- If BLOCKED: the user knows which rows/ACs need attention and the fix paths, and no closeout line was written.
- If PASS: the closeout contract ran, and the user knows the next step is run-gate then `gh pr create`.

## Common false-positive sources (and the fix)

- **Handler exists but the plan's path cell is wrong** (wrong file, or `:token` not literally present). Fix the matrix row, re-run.
- **Test-name typo.** Grep the repo for the AC ID; make the literal read exactly `AC-N (SURFACE)`.
- **Token mismatch.** The audit greps the literal token from the path cell. If plan says `:/api/version` but code registers `/api/v1/version`, fix one to match.
