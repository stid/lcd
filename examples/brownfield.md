# Brownfield — adopting LCD in an existing repo

The harder sell than a fresh project: a years-old repo with its own docs, an ADR folder, mixed
test conventions, and history nobody fully remembers. LCD's onboarding is **retrofit-safe**
(skip-on-conflict, never overwrite), so adoption is one pass plus a health check. Worked example:
a 5-year-old Node service with `docs/adr/` (14 ADRs), Jest, and a `CLAUDE.md` that already has
house rules.

## 1. Onboard

```
/lcd:onboard
```

Onboarding is a single interaction — up to three questions in one prompt (artifact placement, the
CI audit gate on GitHub repos, and a living spec). What happens differently in a brownfield repo:

- **Artifact placement (the main question):** the detected `docs/adr/` shows up as an option.
  Picking `docs/lcd/` (recommended) keeps LCD's spine separate and **links** the ADR dir instead
  of duplicating it; picking `docs/adr/` makes that dir the artifact root (and onboard writes the
  `ac-convention` override so the AC rule auto-loads there).
- **Existing decisions are imported as seeds.** `DECISIONS.md` gets one entry per *notable
  detected choice* (framework, test runner, monorepo tool), each marked `detected at onboarding —
  confirm/edit`. For an existing ADR dir, the seed is a pointer entry ("D-001 · Prior ADRs:
  docs/adr/ is the historical record; superseding decisions land here") — don't migrate 14 ADRs
  by hand, supersede them one at a time as they come up.
- **`MAP.md` is generated from the real structure** — for a legacy repo this is usually the
  single highest-value artifact: the first written-down answer to "where does what live, and
  what must I not put where."
- **Existing `CLAUDE.md` is appended, not replaced** — the ~12-line LCD pointer lands at the end;
  house rules stay. Anything that smells like a must-restate constraint also gets copied into the
  conventions file's Constitution notes, so Deep-lane plans honor it.
- **Jest gets the non-watch form** (`jest --watchAll=false`) in `scoped-test`/`bail` — the most
  common brownfield foot-gun, since bare `jest` watches and would hang the red-green loop.
- **Anything that already exists is skipped and logged**, never overwritten.

## 2. Health-check

```
/lcd:doctor
```

Expect WARNs on a brownfield repo (e.g. a placement/discovery-glob mismatch because old tests
live in two conventions). Fix the FAILs — typically a watch-mode command or a placeholder the
detection couldn't infer — and re-run until `0 FAIL`.

## 3. First work-item (and the first re-route)

Brownfield estimates are wrong more often — that's what re-routing is for, not a reason to
over-triage up front:

```
> tighten the retry logic in the billing client
LCD → Quick (1 signal): no artifacts. 2 files, known cause, one sitting.
```

Mid-work it turns out three call-sites duplicate the retry loop and the fix wants a shared
helper used by five files:

```
Re-routing Quick → Standard: opening work/billing-retry/JOURNAL.md, backfilling S1–S2 from
work already done. (D-016: re-routed — retry logic was duplicated 3×, extraction spans files.)
```

The work carries forward — nothing restarts. The JOURNAL's EDIT BOUNDARY now also makes the
plugin's boundary hook active: an edit outside the declared paths is denied with the fix named
(extend the boundary via `lcd:refine`), which on a tangled legacy codebase is exactly the
"don't pull the thread" guardrail you want.

## What you do NOT need

- No big-bang migration of existing docs/tests/ADRs. LCD only adds its spine and supersedes
  decisions as they're actually revisited.
- No CI changes unless you opted into the audit-gate workflow at onboarding (you can re-run
  `/lcd:onboard` later to add it).
- No rename of anything that exists. If a generated artifact conflicted, it was skipped — check
  `lcd:onboard-skipped.log`.
