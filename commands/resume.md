---
description: LCD — run after a context reset or in a fresh session picking up an in-flight work-item; rebuilds working context in minimal tokens
argument-hint: "<slug>"
---

You are **resuming a Lean Context Development work-item after a context reset**. The whole point is to rebuild *just enough* context to continue — cheaply. Don't read the full spec/plan/tasks unless the next action demands it.

Target slug: `$ARGUMENTS`

## Resolve paths

Read `.claude/rules/lcd-conventions.md`'s `<!-- lcd-conventions:v1 -->` block for `artifact-root` (default `docs/lcd`). The work-item dir is `<artifact-root>/work/<slug>/`. If `$ARGUMENTS` is empty, list the work-item dirs under `<artifact-root>/work/` and ask which slug to resume.

## Rebuild in this exact order (stop as soon as you can name the next action)

1. **Read `<artifact-root>/MAP.md`** — the project guardrails. This is the only project-wide read.

2. **Extract only the `lcd-resume:v1` block** from `<artifact-root>/work/<slug>/JOURNAL.md` — the fenced top section (NOW, STEPS, local DECISIONS, OPEN QUESTIONS, EDIT BOUNDARY). Skip the LOG, the DEEP PIPELINE detail, and the full pipeline files. Practical extraction:

   ```bash
   awk '/<!-- lcd-resume:v1 -->/{f=1;next} /<!-- \/lcd-resume -->/{f=0} f' <artifact-root>/work/<slug>/JOURNAL.md
   ```

3. **Read `<artifact-root>/DECISIONS.md` headers only** (the `## D-NNN · …` lines + Status). Expand a full block only if a STEP or OPEN QUESTION references that `D-NNN`.

4. **Deep lane only:** read the single DEEP PIPELINE checklist line in the JOURNAL. Open `spec.md` / `plan.md` / `tasks.md` **only if** the Next action requires their detail (e.g. "continue red-green" needs the failing test + plan EDIT BOUNDARY, which the JOURNAL already carries — so often you still don't need them).

5. **Staleness check — do this before trusting the JOURNAL.** Compare the JOURNAL's `Branch` + `Updated` against git:

   ```bash
   git rev-parse --abbrev-ref HEAD            # current branch vs JOURNAL Branch
   git log -1 --format=%cd --date=short       # last commit date vs JOURNAL Updated
   ```

   If the current branch differs from the JOURNAL `Branch`, or HEAD is newer than `Updated` (commits landed since the JOURNAL was written), **warn the user the resume anchor may be stale** and offer to reconcile (read recent `git log`/diff) before proceeding. A stale anchor that lies is worse than re-reading source.

## Then

State a **one-line situation summary** + the **Next action** verbatim from NOW, and proceed with that action. If OPEN QUESTIONS contains a blocker, surface it first instead of proceeding.

## Token discipline

Target under ~2k tokens to resume: MAP (~1–1.5k) + resume block (~0.4k) + decision headers (~0.3k). If you find yourself opening spec+plan+tasks in full, stop — either the Next action is genuinely detail-heavy (fine) or the JOURNAL NOW/STEPS are too thin (fix them as you go so the next resume is cheap).
