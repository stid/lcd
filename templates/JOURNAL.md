# JOURNAL — <SLUG>

> **The resume anchor.** The block between the `lcd-resume:v1` markers below is the *entire*
> cold-start payload — everything a fresh session needs to continue, in <~40 lines. `/lcd:resume`
> reads MAP.md + this block + DECISIONS headers and nothing else. Keep NOW and STEPS current as
> you work (the build loop and `lcd:refine` update them as part of their normal edit/commit
> step). Everything below the `---` is history/detail, NOT read on resume.

<!-- lcd-resume:v1 -->
## NOW
- **Lane:** <Quick | Standard | Deep>
- **Goal:** <one sentence — what this work-item delivers>
- **Next action:** <the single next concrete step a fresh session should do first>
- **Branch:** <git-branch>  ·  **Updated:** <YYYY-MM-DD HH:MM>

## STEPS
- [x] S1 — <completed step>
- [ ] S2 — <pending step>  ← next
- [ ] S3 — <pending step>

## DECISIONS (this work-item)
- <slug-local choice + one-line why>  <!-- mirror durable ones into DECISIONS.md as D-NNN -->

## OPEN QUESTIONS
- <blocking unknown, or "none">

## EDIT BOUNDARY (paths this work may touch)
- `<path>`
<!-- /lcd-resume -->

---

## Acceptance criteria

<Only when a surface needs the audit (Standard lane with a CLI/HTTP/MCP/RENDER/DB/EVAL
surface, or any Deep lane). Format per the ac-convention rule: `**AC-N** (surfaces: <CSV>): <body>`.
Omit this section entirely for internal-only work.>

## LOG (append-only; not read on resume)

- <YYYY-MM-DD HH:MM> — <what happened: step completed, decision made (→ DECISIONS D-NNN), recon finding, refinement>

## DEEP PIPELINE (Deep lane only)

> Phase tracker for the Deep-lane pipeline. Files live beside this JOURNAL.

`spec.md ⬜  plan.md ⬜  tasks.md ⬜  tests ⬜  red-green ⬜  audit.md ⬜`
<!-- mark ✅ done · ⏳ in progress · ⬜ not started -->

<!--
Resume contract (why the block above is fenced):
  /lcd:resume extracts ONLY the lcd-resume:v1 block. If NOW/STEPS are stale, resume
  rebuilds a false context — so update them in the same edit where you change the work.
  /lcd:resume also cross-checks `Updated` + `Branch` against `git log` and warns if this
  JOURNAL is older than HEAD before trusting it.
-->
