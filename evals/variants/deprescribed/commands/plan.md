---
description: LCD Deep lane phase 2 — run once spec.md is approved (open questions resolved); creates plan.md (architecture, file map)
argument-hint: "<slug>"
---

You are running **Deep-lane phase 2 of Lean Context Development**. See the `lcd:triage` skill for orchestration rules.

Target slug: `$ARGUMENTS`

## Setup

**Resolve the artifact root** from `.claude/rules/lcd-conventions.md` (`artifact-root`, default `docs/lcd`). Work item: `<artifact-root>/work/<slug>/`.

**Read `<artifact-root>/MAP.md` first** — its Zones and Invariants ground the architecture and the Constitution check.

## Goal

Produce `<artifact-root>/work/<slug>/plan.md` — the how for an approved spec — starting from `${CLAUDE_PLUGIN_ROOT}/templates/plan.md`, grounded in the spec and the MAP, and keep the work-item JOURNAL in sync (EDIT BOUNDARY = the plan's File-structure paths; Next action = "run /lcd:tasks <slug>"; `plan.md ✅` in the tracker). Order your own steps; the gates and constraints below are the contract.

## Gates (check before writing anything)

- **Refuse if `spec.md` does not exist** — tell the user to run `/lcd:specify <slug> "<feature>"` first.
- **Refuse if the spec has unresolved open questions.** Unresolved means: `- [ ]` checkbox lines, AND any plain bullet that isn't `- [x]` / a resolved note. Tell the user which need answers and offer to walk through them via `AskUserQuestion`. An empty section or only `- [x]` passes.
- **Refuse if `plan.md` already exists.** Ask whether to (a) edit existing, (b) abandon, or (c) move it aside and start fresh.

## Constraints (the artifact contract)

- Every template section is genuinely filled (title/slug/date; one-sentence Goal derived from the spec).
- **Architecture** states the approach and the rejected alternatives (one sentence each); new-dependency / new-pattern choices are grounded in a `lcd:recon` finding where one applies; durable choices are mirrored into `<artifact-root>/DECISIONS.md`.
- **Constitution check is honest:** the constitution is LCD's bundled rules at `${CLAUDE_PLUGIN_ROOT}/rules/` (`testing`, `no-overengineering`, `no-downgrade`, `refinement-protocol`, `versioning`, `commits`) + this project's `CLAUDE.md` + project rules under `.claude/rules/` (a project rule overrides the bundled one of the same name) + `MAP.md` invariants. One row per rule/invariant that materially constrains the plan. **Read the rule file before declaring compliance — don't bluff.**
- **Cross-path behavior matrix** whenever the same behavior is exposed through more than one surface: one row per non-`none` (AC × surface) pair; path cells use `<file>:<token>` for CLI/HTTP/MCP and bare `<file>` for RENDER/DB/EVAL. Symbol-level coverage is not sufficient. Single-surface-only specs skip the section header entirely.
- **Reused primitives is non-empty** — grep the codebase (start from `MAP.md` Zones); if truly nothing applies, write "framework + test runner only".
- **File structure is concrete** (new + modified files, one-line purpose each) — concrete enough to translate directly into `tasks.md` and the JOURNAL EDIT BOUNDARY.
- On a real architecture fork (2+ viable approaches), use `AskUserQuestion`; the chosen approach goes in the plan, rejections into "Risks & rejected alternatives" (and DECISIONS.md when durable).
- Finish by telling the user: the plan path, any constitution rows implying non-trivial work, the primitives being reused, and that `/lcd:tasks <slug>` is next.

## What NOT to do

- Don't write tasks (phase 3) or modify any source files.
- Don't skip the constitution check — it's the bridge between the project's rules and LCD.
- Don't contradict the spec — if the spec needs amendment, edit `spec.md` and call it out explicitly.
