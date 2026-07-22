---
name: refine
description: Autonomously correct a LCD work-item's plan when reality drifts from it — a STEP/task that's now wrong, a task that needs splitting, a MAP zone/invariant that no longer matches the code, or stale knowledge. Updates the artifact AND logs the change without waiting to be asked. Use mid-work when you notice the recorded plan no longer matches what the work actually needs.
user-invocable: true
---

# LCD Refine

Keeps the durable artifacts honest when plans drift, **without** waiting for the user to ask — a
stale JOURNAL/MAP that lies is worse than none (it poisons the next resume).

## When it fires (autonomously)

Invoke this whenever, mid-work, you notice any of:
- A JOURNAL **STEP** or a Deep-lane **task** is wrong, out of order, or needs splitting/merging.
- The **EDIT BOUNDARY** needs a path the plan didn't anticipate (this is also a plan File-structure
  change — make both).
- The **MAP** no longer matches reality (a new zone, a moved responsibility, a retired/added
  invariant, a newly-exposed surface).
- A recorded **decision** is now wrong or superseded, or **knowledge** captured earlier is stale.

## The protocol (bounded by refinement-protocol)

Per the global `refinement-protocol` rule — even though no one asked, hold yourself to it:

1. **Restate** the specific change: "STEP S3 splits into S3a (write resolver test) + S3b (impl)
   because …".
2. **List what stays unchanged** — the surrounding STEPS/tasks/zones you are NOT touching.
3. **Make the edit** to the artifact (JOURNAL STEPS, tasks.md, plan.md File-structure + EDIT
   BOUNDARY, or MAP.md), then:
4. **Log it.** Append a dated one-line entry to the JOURNAL **LOG** ("refined: S3 split — plan target
   moved to src/foo"). If the change is **durable** (affects the project beyond this work-item — a
   MAP invariant, a superseded decision), also add/supersede an entry in `<root>/DECISIONS.md`.

## Autonomy boundary — when to STOP and ask instead

Refine quietly for **in-scope mechanical drift** (the plan was right in spirit, the details moved).
**Escalate to the user** when the drift implies a change of *intent*:
- The spec's acceptance criteria would change (that's a `/lcd:specify` edit, a real scope change).
- A decision reversal that the user explicitly made.
- The work no longer matches its stated Goal.
In those cases, surface the discrepancy and ask — don't silently rewrite intent.

## Keep it light

Refine is a small correction + a log line, not a re-plan. If you're rewriting half the JOURNAL, the
work changed enough that triage should re-run (it may belong in a different lane) — say so rather
than forcing the old artifact to fit.
