---
description: LCD Deep lane phase 4 — run once tasks.md exists; generates failing tests from spec.md ACs, one per (AC × surface)
argument-hint: "<slug>"
---

You are running **Deep-lane phase 4 of Lean Context Development**. See the `lcd:triage` skill for orchestration and the `ac-convention` rule for the AC format you'll parse.

Target slug: `$ARGUMENTS`

## Setup

**Resolve the artifact root** from `.claude/rules/lcd-conventions.md` (`artifact-root`, default `docs/lcd`). Work item: `<artifact-root>/work/<slug>/`.

**Detect the test framework** from the project root and use its idiom:

| Marker                                | Framework  | Test file                        | Import / decl                             |
| ------------------------------------- | ---------- | -------------------------------- | ----------------------------------------- |
| `bun.lockb`                           | bun:test   | `tests/<slug>/<surface>.test.ts` | `import { test, expect } from "bun:test"` |
| node/pnpm/yarn with `vitest` in deps  | Vitest     | `tests/<slug>/<surface>.test.ts` | `import { test, expect } from "vitest"`   |
| node/pnpm/yarn otherwise              | Jest       | `tests/<slug>/<surface>.test.js` | Jest globals (`test`, `expect`)           |
| `pyproject.toml` / `requirements.txt` | pytest     | `tests/<slug>/test_<surface>.py` | `import pytest`                           |
| `Cargo.toml`                          | cargo test | `tests/<slug>_<surface>.rs`      | `#[test]`                                 |
| `go.mod`                              | go test    | `<pkg>/<slug>_<surface>_test.go` | `func TestX(t *testing.T)`                |

**Project override:** if `.claude/rules/lcd-conventions.md` exists, its `test-placement` key overrides the default test path (emit there — needed when the runner only collects a custom glob), and its `scoped-test` key overrides the red-confirmation command. **Monorepo:** zone-scoped variants (`test-placement[<path-prefix>]:`, `scoped-test[<path-prefix>]:`) override the bare keys when the plan's File-structure targets sit under that prefix — longest matching prefix wins (see the plugin's `docs/monorepos.md`).

## Goal

Emit the work-item's failing tests — **one per (AC × non-`none` surface) pair, plus one per `none` AC** — grouped by surface into separate files under the framework's test dir (or the placement override), grounded in the spec's AC bodies and the plan matrix's AC→file bindings, and confirmed red. Then mark `tests ✅` in the JOURNAL, set Next action = "run lcd:redgreen-loop", and hand off to the `lcd:redgreen-loop` skill (phase 5) or a manual red-green cycle. Order your own steps; the gates and constraints below are the contract.

## Gates (check before writing anything)

- **Refuse if `spec.md`, `plan.md`, `tasks.md` are not all present** under `<artifact-root>/work/<slug>/`. Tell the user which phase is missing.
- **Parse the ACs with `parse-acs.sh <artifact-root>/work/<slug>/spec.md`** (rows are tab-separated `<AC-id>\t<surfaces-CSV>\t<body>`). Refuse to continue if it exits non-zero — the spec is malformed and must be fixed first.

## Constraints (the test contract)

- **The literal `AC-N (SURFACE)` string is non-negotiable** — it is what `/lcd:audit` greps for:
  - JS/TS: `test("AC-<N> (<SURFACE>): <short>", () => { … })`
  - pytest: `def test_ac_<N>_<surface>():` with first docstring line `"""AC-<N> (<SURFACE>): <short>"""`
  - Rust: `#[test] fn ac_<n>_<surface>()` preceded by `// AC-<N> (<SURFACE>): <short>`
  - Go: `func TestAC<N><Surface>(t *testing.T)` preceded by `// AC-<N> (<SURFACE>): <short>`
  - For a `none`-surface AC, drop the suffix: `AC-<N>: <short>`.
- **Plan.md's Cross-path behavior matrix is the authoritative AC→file binding** — each test exercises the path its matrix row declares (invoke the entry point named in the matrix; call the helper for `none`; load the golden dataset + assert the threshold for `EVAL`, with `skipIf` on a missing API key for non-deterministic evals).
- **Tests must fail** — write them assuming the implementation doesn't exist yet, then **run the detected test command scoped to the new tests** to confirm red, and print the failing test names.
- **Reuse existing test helpers/fixtures** — grep before writing new ones.

## What NOT to do

- Don't write implementation code — phase 4 is tests-only.
- Don't skip `none`-surface ACs — they need a test, just without the surface suffix.
- Don't invent scenarios beyond the AC body — one test per (AC × surface).
- Don't modify existing tests outside the new `tests/<slug>/` dir.

## Quality gate before declaring done

- One test per (AC × non-`none` surface), plus one per `none` AC.
- The scoped test run exits non-zero (red, as expected).
- Every test carries the literal `AC-N (SURFACE)` (or `AC-N`) — grep the new files to verify.
