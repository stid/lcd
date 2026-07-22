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
- **EVAL coverage:** a feature touching a path whose output can be *silently wrong* (scorer, ranker, recommender, LLM output) carries at least one `EVAL` AC — or you're prepared to justify its absence in `plan.md` (see the ac-convention rule).
- Material branch points go through `AskUserQuestion`; simple fact-gathering stays inline; durable decisions are mirrored into `<artifact-root>/DECISIONS.md`.
- Finish by telling the user the spec path and which open questions still block `/lcd:plan <slug>`.

## What NOT to do

- Don't write `plan.md` or `tasks.md` — those are phases 2 and 3.
- Don't propose a solution — the spec captures the problem, not the answer.
- Don't skip the "Out of scope" or "Open questions" sections — they're guardrails.
