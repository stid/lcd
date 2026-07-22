# Spec: <FEATURE_TITLE>

> **Deep lane · Phase 1 of 6 (Specify).** This document owns **what** and **why**. No tech
> stack, no file paths, no function names. Move all of that to `plan.md` in Phase 2.

**Slug:** `<SLUG>`
**Created:** <YYYY-MM-DD>
**Related issue:** <#NN or "none">
**Status:** draft <!-- draft | approved | implemented | abandoned -->

---

## Problem

<One paragraph: what is broken or missing, who feels the pain, what evidence motivates this work. No proposed solution.>

## User stories

<At least one. Format: "As a <role>, I want <capability>, so that <outcome>.">

- As a <role>, I want <capability>, so that <outcome>.

## Acceptance criteria

<Every AC follows the format `**AC-N** (surfaces: <CSV>): <body>`. Surface tokens are drawn from the fixed vocabulary `CLI | HTTP | MCP | RENDER | DB | EVAL | none` — use whatever subset applies to this project. See the ac-convention rule for the full convention. The format is what `/lcd:test-gen` parses to emit failing tests and what `/lcd:audit` binds back to handlers. Use `EVAL` for a measurable quality threshold over a frozen golden dataset; for paths whose output can be silently wrong (LLM output, scorers, rankers), also state an explicit must-not (the forbidden behavior, in the AC body or a companion negative AC) — not just the positive criterion.>

**AC-1** (surfaces: CLI): Given <…>, when <…>, then <…>.

**AC-2** (surfaces: HTTP): Given <…>, when <…>, then <…>.

**AC-3** (surfaces: none): The <internal helper / invariant / calculation> behaves as <…>.

## Out of scope

<Explicit non-goals. Things a reasonable reader might assume are in scope but aren't. Saves arguments later.>

- <…>

## Open questions

<Things unresolved here. They MUST be answered before `/lcd:plan` runs. Resolve in conversation or by editing this file.>

- [ ] <…>

---

<!--
Quality checks before approving this spec:
  - No tech stack named (no language / framework / database appears anywhere)
  - No file paths or function names
  - Every acceptance criterion follows `**AC-N** (surfaces: <CSV>): <body>`
  - Surface tokens are exactly from {CLI, HTTP, MCP, RENDER, DB, EVAL, none}
  - Every acceptance criterion is testable (you can describe an assertion that proves it)
  - Out-of-scope is filled in, even if just one bullet
  - Open questions either all answered, or explicitly flagged for /lcd:plan to resolve
-->
