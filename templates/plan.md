# Plan: <FEATURE_TITLE>

> **Deep lane · Phase 2 of 6 (Plan).** This document owns **how**. Specify ≠ Plan: if you're
> about to write a user story or acceptance criterion, that belongs in `spec.md`.

**Slug:** `<SLUG>`
**Spec:** [`spec.md`](./spec.md) · **Journal:** [`JOURNAL.md`](./JOURNAL.md)
**Created:** <YYYY-MM-DD>
**Status:** draft <!-- draft | approved | implemented | superseded -->

---

## Goal

<One sentence restating what this plan delivers. Should be derivable from `spec.md` — if it's not, the spec is wrong.>

## Architecture

<2–5 paragraphs. The approach, the key decisions, the rejected alternatives in one sentence each. Diagrams welcome (mermaid or ASCII). Ground new-dependency / new-pattern choices in a `lcd:recon` finding — cite the current-best-practice bullet that informed them, and mirror durable choices into `DECISIONS.md`.>

## Constitution check

<The "constitution" is LCD's bundled rules at `${CLAUDE_PLUGIN_ROOT}/rules/` + this project's `CLAUDE.md` + any rule under `.claude/rules/` (a project rule overrides the bundled one of the same name) + this project's `MAP.md` invariants. This table calls out the rules that materially constrain this plan and declares how the plan complies. Read each rule file before declaring compliance — don't bluff. The always-on rows below are the bundled rules; add one row per project-local `.claude/rules/*` and per `MAP.md` invariant that applies.>

| Rule | Applies? | Compliance note |
|---|---|---|
| `testing.md` (tests first, coverage) | yes (always) | <TDD per the redgreen loop> |
| `no-downgrade.md` (preserve features) | yes (always) | <existing features preserved: …> |
| `no-overengineering.md` (minimal scope) | yes (always) | <minimal scope: …> |
| `refinement-protocol.md` (ambiguous edits) | yes (always) | <ambiguity resolved before code edits> |
| `versioning.md` (bump in first commit) | yes (always) | <minor/patch bump in first commit of this branch> |
| `ac-convention.md` — EVAL coverage (quality / LLM-output paths) | yes/no | <≥1 EVAL AC in the spec, or why an eval isn't warranted> |
| `MAP.md` invariant: <name> | yes/no | <how this plan respects it> |
| `<.claude/rules/project-rule.md>` | yes/no | <how this plan respects it> |

## Cross-path behavior matrix

> **Required when the same conceptual behavior is exposed through more than one surface** (e.g. a CLI command and an HTTP route that do the same thing). Skip the section header entirely if every AC has a single surface.

The constitution check tells you *whether* parallel paths exist; this matrix tells you *what behavior must be identical across them*. List every AC from `spec.md` that has a non-`none` surface tag, then for each surface token declared on that AC, name the path that implements it.

**Path-cell convention (this is the audit contract):**
- For a surface whose contract is "a specific handler is wired" (CLI / HTTP / MCP), write `<file>:<token>` — the file to grep and the literal token to find (the command name, the route, the tool name). The audit greps `<file>` for the literal `<token>`.
- For a surface whose contract is "this file is present" (RENDER / DB, or an `EVAL` golden dataset), write just `<file>`. The audit does a file-exists check.

| AC | Surface | Path |
|---|---|---|
| `AC-1` | CLI | `<cli-entry-file>:<command-name>` |
| `AC-2` | HTTP | `<router-file>:/api/foo` |
| `AC-N` | EVAL | `<golden-dataset-file>` |
| `<…>` | | |

Every row becomes (a) a task in `tasks.md` and (b) a target row in `/lcd:audit`. The audit reads this matrix to look up the exact path per (AC × surface) — if a row is missing here, the audit refuses to run (BLOCKED).

Verify the **behavior** ("every surface emits the source label"), not just the **symbol** ("every caller of resolveX"). Symbol-level coverage misses parallel surfaces that don't share a code path.

## Reused primitives

<Existing functions, modules, tools, or utilities this plan leans on. If something already does X, name it here and don't reimplement. This is the anti-overengineering bulwark. Check `MAP.md` Zones first. If truly nothing applies, write "framework + test runner only".>

| Existing primitive | Path | Used for |
|---|---|---|
| `<function or module>` | `<path>` | <what role it plays> |

## Data model / Contracts

<If this introduces or changes types, DB schema, tool shapes, or API endpoints, describe them here. Skip the section if not applicable.>

## File structure

> This section is the source of truth for the JOURNAL **EDIT BOUNDARY**. The red-green loop may
> only modify paths listed here; copy them into the work-item JOURNAL's EDIT BOUNDARY block.

### New files

```
<list with one-line purpose per file>
```

### Modified files

- `<path>` — <what changes>

## Risks & rejected alternatives

<Optional. Anything non-obvious a reviewer might ask "why didn't you…" — answer it here, briefly. Durable rejections belong in `DECISIONS.md`.>

- **<Alternative>**: rejected because <…>

---

<!--
Quality checks before approving this plan:
  - Every spec acceptance criterion maps to something in this plan
  - Constitution check has at least one filled-in row beyond the always-on bundled rules
  - If behavior is multi-surface → matrix has one row per (AC × non-`none` surface) pair, each cell in the <file>:<token> or <file> convention above
  - Every AC ID referenced in the matrix matches the spec.md (no orphan rows, no missing ACs)
  - Reused primitives section is non-empty (something is being reused — even if just the test framework)
  - File structure is concrete enough to translate directly into tasks.md AND the JOURNAL EDIT BOUNDARY
-->
