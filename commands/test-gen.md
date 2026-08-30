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

**Project override:** if `.claude/rules/lcd-conventions.md` exists, its `test-placement` key overrides the default test path (emit there — needed when the runner only collects a custom glob), and its `scoped-test` key overrides the command in step 7. **Monorepo:** zone-scoped variants (`test-placement[<path-prefix>]:`, `scoped-test[<path-prefix>]:`) override the bare keys when the plan's File-structure targets sit under that prefix — longest matching prefix wins (see the plugin's `docs/monorepos.md`).

## What to do

1. **Refuse if `spec.md`, `plan.md`, `tasks.md` are not all present** under `<artifact-root>/work/<slug>/`. Tell the user which phase is missing.

2. **Parse ACs from spec.md:**

   ```bash
   parse-acs.sh <artifact-root>/work/<slug>/spec.md
   ```

   Each row is tab-separated: `<AC-id>\t<surfaces-CSV>\t<body>`. Refuse to continue if the script exits non-zero — the spec is malformed and must be fixed first.

3. **Read plan.md's Cross-path behavior matrix** for the path per (AC × surface) pair — the authoritative AC→file binding.

4. **Emit one failing test per (AC × non-`none` surface) pair**, plus one per `none` AC. Group by surface into separate files under the framework's test dir (or the placement override).

5. **The literal `AC-N (SURFACE)` string is non-negotiable** — it is what `/lcd:audit` greps for:
   - JS/TS: `test("AC-<N> (<SURFACE>): <short>", () => { … })`
   - pytest: `def test_ac_<N>_<surface>():` with first docstring line `"""AC-<N> (<SURFACE>): <short>"""`
   - Rust: `#[test] fn ac_<n>_<surface>()` preceded by `// AC-<N> (<SURFACE>): <short>`
   - Go: `func TestAC<N><Surface>(t *testing.T)` preceded by `// AC-<N> (<SURFACE>): <short>`
   - For a `none`-surface AC, drop the suffix: `AC-<N>: <short>`.

6. **Tests must fail.** Exercise the AC body assuming the implementation doesn't exist yet (invoke the entry point named in the matrix; call the helper for `none`; load the golden dataset + assert the threshold for `EVAL`, with `skipIf` on a missing API key for non-deterministic evals). Reuse existing test helpers/fixtures — grep before writing new ones.

7. **Run the detected test command scoped to the new tests** to confirm they are red. Print the failing test names.

8. **Update the JOURNAL:** mark `tests ✅`; set Next action = "run lcd:redgreen-loop". **Hand off** to the `lcd:redgreen-loop` skill (phase 5) or a manual red-green cycle.

## AC examples (the shapes you'll parse)

```
**AC-1** (surfaces: CLI, HTTP, MCP): Given a config key is set in the environment, when any path resolves that key, then the environment value is used.

**AC-2** (surfaces: HTTP): Given /api/doctor is called, when the env-var source supplies the key, then the response includes a `key_source` field set to "env".

**AC-3** (surfaces: none): The resolver returns the first non-empty source in the precedence chain (env → config file).

**AC-4** (surfaces: EVAL): Given the frozen reference set, when the scorer's calibration error is measured, then the mean absolute error stays at or below the declared threshold.

**AC-5** (surfaces: EVAL): Given the frozen counter-example set, when the assistant answers a wrong-item complaint, then the response does NOT emit a raw policy paragraph and does NOT ask for information already supplied in the message.
```

`AC-5` is the must-not companion: same EVAL format, body phrased as a forbidden behavior, scored against counter-examples in the golden dataset — its test asserts the forbidden behavior is absent.

## What NOT to do

- Don't write implementation code — phase 4 is tests-only.
- Don't skip `none`-surface ACs — they need a test, just without the surface suffix.
- Don't invent scenarios beyond the AC body — one test per (AC × surface).
- Don't modify existing tests outside the new `tests/<slug>/` dir.

## Quality gate before declaring done

- One test per (AC × non-`none` surface), plus one per `none` AC.
- The scoped test run exits non-zero (red, as expected).
- Every test carries the literal `AC-N (SURFACE)` (or `AC-N`) — grep the new files to verify.
