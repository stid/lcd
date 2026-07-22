---
description: LCD Deep lane phase 3 — run once plan.md is approved; generates tasks.md (dependency-ordered checklist)
argument-hint: "<slug>"
---

You are running **Deep-lane phase 3 of Lean Context Development**. See the `lcd:triage` skill for orchestration rules.

Target slug: `$ARGUMENTS`

## Setup

**Resolve the artifact root** from `.claude/rules/lcd-conventions.md` (`artifact-root`, default `docs/lcd`). Work item: `<artifact-root>/work/<slug>/`.

**Detect the toolchain** for the final task: prefer `lcd-conventions.md`'s `gate` key; otherwise infer test + lint + typecheck commands from the project's lockfile/manifest (bun/pnpm/yarn/npm, Cargo, uv/pyproject, go.mod). Use only commands the project actually has.

## Goal

Produce `<artifact-root>/work/<slug>/tasks.md` — a flat, dependency-ordered, TDD checklist translating the plan into executable steps — starting from `${CLAUDE_PLUGIN_ROOT}/templates/tasks.md`, and mirror it into the JOURNAL STEPS (S1..Sn) as the resume view, with Next action = "run /lcd:test-gen <slug>" and `tasks.md ✅` in the tracker. Order your own steps; the gates and constraints below are the contract.

## Gates (check before writing anything)

- **Refuse if `spec.md` or `plan.md` is missing** — tell the user which phase to run.
- **Refuse if `tasks.md` already exists.** Ask whether to (a) edit, (b) abandon, or (c) move aside and regenerate.

## Constraints (the artifact contract)

- **Tests first:** every implementation task's proving test precedes it; cross-path ACs get one test task per surface so the literal `AC-N (SURFACE)` maps one-to-one to a task.
- **One file per task** where possible (split unless genuinely atomic); **every task names the file it touches**; dependency order holds (if T5 needs T2's exports, T5 comes after T2); `[P]` marks tasks runnable in parallel with the previous one.
- **`T-audit` before `T-final`:** T-audit runs `/lcd:audit <slug>` to zero MISSING/BLOCKED rows; T-final runs the detected test + lint + typecheck, all green.
- **Coverage is complete:** every AC has ≥1 task; every new file in the plan's File structure has a creating task; every modified file has a modifying task; the Linkbacks section maps `AC-N → T-X`.
- Finish by telling the user: the tasks.md path, total + parallel-eligible counts, the first task and its AC, and the pipeline ahead (`/lcd:test-gen` → `lcd:redgreen-loop` → `/lcd:audit`).

## What NOT to do

- Don't start implementation or write the first failing test — that's phase 4.
- Don't add tasks not justified by spec ACs or plan file structure — if something seems missing, edit the upstream artifact first.
