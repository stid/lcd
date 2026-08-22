---
description: LCD — run periodically, or when finished/abandoned work-items accumulate; prunes stale work-items and runs the maintenance bundle
---

You are running **LCD tidy** — the recurring maintenance pass that keeps a project's context lean. Stale files waste tokens and confuse future sessions; this command removes them and runs the curated maintenance bundle. **Nothing is deleted without showing the plan and getting confirmation.**

## Resolve paths

Read `.claude/rules/lcd-conventions.md`'s `<!-- lcd-conventions:v1 -->` block for `artifact-root` (default `docs/lcd`) and `maintenance-bundle`.

## What to do

1. **Inventory work-items.** For each `<artifact-root>/work/<slug>/`, read the JOURNAL `NOW` block:
   - **Done + merged** — NOW says the work is complete (all STEPS checked, or Status done) AND its branch is merged/gone (`git branch --merged` contains the JOURNAL `Branch`, or the branch no longer exists). → **prune candidate** (archive or delete the folder).
   - **Abandoned** — JOURNAL/spec Status is `abandoned`. → prune candidate.
   - **Active** — anything else. → leave untouched.

2. **Scan MAP for drift.** Flag (do not auto-edit) `MAP.md` Zones whose paths no longer exist, and "Surfaces in use" / Invariants that look out of date. List them for the user; suggest `lcd:refine` or a `/lcd:onboard` refresh if drift is significant. Also flag **DECISIONS staleness**: report commits since `DECISIONS.md` was last touched (`git log -1 --format=%cd --date=short -- <artifact-root>/DECISIONS.md`, then count commits since) — a long gap means decisions are being made without being recorded. If `living-spec: on`, also flag **SPEC staleness**: grep `SPEC.md` for `stale:` markers (rows Quick-lane work changed after their last fold) and list them with their dates — an old marker means the index is lagging reality there; the next work-item touching that capability clears it via `reconcile`, or run a targeted `lcd:refine` if it lingers.

3. **Detect other stale content** (report, don't auto-delete): empty/placeholder work-item dirs (only a never-filled JOURNAL), leftover `STUCK.md` for a feature that later merged, `tests/<slug>/` dirs whose work-item folder is gone.

4. **Present the plan and STOP for confirmation** (per `refinement-protocol`): list exactly what would be pruned (full paths), what would be archived vs deleted, and what MAP drift was flagged. Do not touch anything until the user approves. Default to **archiving** completed work-items (e.g. move to `<artifact-root>/work/_archive/<slug>/`) rather than deleting, unless the user asks to delete.

5. **On approval, prune**, then **run the maintenance bundle.** If `maintenance-bundle` is set, run each command (semicolon-separated) in the foreground and report pass/fail. Otherwise run the detected `gate` command. Typical bundle: the gate (test+lint+typecheck), a dependency-staleness check, a format pass.

6. **Report**: the **lane distribution** from `<artifact-root>/triage-log.md` if it exists (count of Quick / Standard / Deep + total, so the user can see whether most work really is Quick and whether Deep is being earned); the **calibration read** from the same log (next step); what was pruned/archived; MAP + DECISIONS drift flagged; and the maintenance-bundle results. If the project is a git repo, show `git status` so the user can review and commit. Do NOT push.

7. **Calibration read (outcome telemetry).** The log carries two line shapes — triage lines (`… · n signals · lane · hard · risk`) and closeout lines (`… · closeout · lane · audit · re-routes · red-green iters · interventions`). Cross-read them and flag:
   - **Under-routing** — a slug with more than one triage line where the lane escalated (Quick→Standard, Standard→Deep), or a closeout with `re-routes > 0` upward. The lighter lane was tried and lost.
   - **Over-routing** — a **Deep** closeout that sailed through: `audit: PASS (first run)`, `re-routes: 0`, `interventions: 0`. One is noise; a pattern means Deep is being over-earned — say which triage signals fired and whether the thresholds look too eager.
   - **Closeout coverage** — Standard/Deep triage lines whose slug never got a closeout (finished work not being measured, or work silently abandoned — suggest closing them out or marking abandoned).
   Two or three flagged lines with slugs is enough; this is a trend report, not an audit.

## What NOT to do

- Do NOT delete or move anything before showing the plan and getting an explicit yes.
- Do NOT delete an **active** work-item, ever.
- Don't edit MAP.md here — flag drift and defer to `lcd:refine` / `/lcd:onboard`.
- Do NOT push or open PRs.

## Cadence (optional /loop recipe — harness feature, never a dependency)

During long autonomous runs, if the harness offers `/loop`, a maintenance cadence keeps drift from
accumulating between sessions: `/loop 2h /lcd:tidy`, or a lighter prompt that runs only the
staleness + closeout-coverage checks and **no-ops silently when nothing changed**. Generous
intervals only, and prefer event-driven triggers where they exist (the Stop hook already guards
the finish line) — `/loop` fills the gaps between events, not replaces them.
