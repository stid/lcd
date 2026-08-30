---
description: LCD Deep lane phase 1 — run when triage routes work to Deep and no spec.md exists yet; creates the feature spec (what & why, no tech)
argument-hint: "<slug> \"<one-line feature description>\""
---

You are running **Deep-lane phase 1 of Lean Context Development**. See the `lcd:triage` skill for lane/orchestration rules and the `ac-convention` rule for the AC format.

Target: `$ARGUMENTS`

## Setup

**Resolve the artifact root.** Read `.claude/rules/lcd-conventions.md`'s `<!-- lcd-conventions:v1 -->` block for `artifact-root` (default `docs/lcd` if the file is absent). Work items live at `<artifact-root>/work/<slug>/`. Create the directory if absent.

## Goal

Produce `<artifact-root>/work/<slug>/spec.md` — a complete what-and-why spec for the feature in `$ARGUMENTS` — starting from `${CLAUDE_PLUGIN_ROOT}/templates/spec.md`, and seed the work-item resume anchor: copy `${CLAUDE_PLUGIN_ROOT}/templates/JOURNAL.md` to the work-item dir if absent, with Lane = Deep, Goal from the feature line, Next action = "run /lcd:plan <slug>", and `spec.md ✅` in the DEEP PIPELINE tracker. Order your own steps; the gates and constraints below are the contract.

## Gates (check before writing anything)

- `$ARGUMENTS` must parse into a kebab-case `<slug>` (first token) and a one-sentence feature line (the rest) — if either is missing or malformed, ask the user inline.
- **Refuse if `<artifact-root>/work/<slug>/spec.md` already exists.** Tell the user and ask whether to (a) edit the existing spec, (b) pick a different slug, or (c) abandon.

## Constraints (the artifact contract)

- Every template section is genuinely filled: Problem, at least one user story (`As a <role>, I want <X>, so that <Y>`), Acceptance criteria, a non-empty Out of scope, Open questions. Metadata too (title, slug, date, related issue or "none").
- **No tech stack in the spec** — no language, framework, database, file paths, or function names. Tech details the user volunteers become a note for `plan.md`, not spec content.
- **Every AC follows `**AC-N** (surfaces: <CSV>)`** with tokens from the fixed vocabulary `CLI | HTTP | MCP | RENDER | DB | EVAL | none`, uses only the applicable subset, cross-checked against `MAP.md`'s "Surfaces in use", and is testable (an assertion could prove it).
- **EVAL coverage:** a feature touching a path whose output can be *silently wrong* (scorer, ranker, recommender, LLM output) carries at least one `EVAL` AC — or you're prepared to justify its absence in `plan.md`. See "EVAL coverage" below.
- Material branch points go through `AskUserQuestion`; simple fact-gathering stays inline; durable decisions are mirrored into `<artifact-root>/DECISIONS.md`.
- Finish by telling the user the spec path and which open questions still block `/lcd:plan <slug>`.

## EVAL coverage (when an EVAL AC is required)

A spec that changes a path whose output can be **silently wrong** — a scorer, a ranker, a recommender, any LLM-generated output — SHOULD include at least one `EVAL` acceptance criterion, OR `plan.md`'s constitution check should state why an eval isn't warranted. Quality regressions in these paths are silent ("plausible but wrong"), so they need a measured gate (error metric, tolerance band, regression bound), not just a presence test. Features with no quality dimension (CRUD endpoints, CLI flags, render tweaks) do not need an EVAL AC. The golden-dataset and the metric harness are **project-local and opt-in** — the framework only asks that the AC name a measurable threshold over a frozen dataset.

State the **must-not** too. For LLM-output / scorer / ranker paths the forbidden behavior is often the load-bearing half of "good" — the failure that embarrasses you is rarely the absence of a positive trait, it's the presence of a bad one (leaks a raw policy paragraph, re-asks for information already supplied, fabricates a citation). A purely positive Given/When/Then ("acknowledges the issue") can pass while the output is still unacceptable. So an `EVAL` AC over a silently-wrong path SHOULD pin at least one explicit must-not / forbidden behavior, phrased *within the AC body* ("…, then the response does NOT do X") or as a **companion negative-bodied AC** — using the ordinary AC format, **not** a new field. The golden dataset then carries the counter-examples (inputs paired with a response that would fail), so the measured gate scores the must-not, not just the must.

## What NOT to do

- Don't write `plan.md` or `tasks.md` — those are phases 2 and 3.
- Don't propose a solution — the spec captures the problem, not the answer.
- Don't skip the "Out of scope" or "Open questions" sections — they're guardrails.
