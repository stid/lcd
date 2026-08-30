---
paths: ["docs/lcd/**/spec.md", "docs/lcd/**/JOURNAL.md"]
---
# Acceptance Criteria Convention

> The AC convention for LCD. `paths:` covers the **default** artifact root (`docs/lcd/**`), so this
> rule auto-loads when you open a spec or JOURNAL there. If a project chose a different
> `artifact-root` at onboarding, `/lcd:onboard` writes a project-local copy of this rule to
> `.claude/rules/ac-convention.md` with `paths:` globs derived from that root (a project rule
> overrides the bundled one of the same name). Used in the Deep lane and in any Standard-lane
> JOURNAL that declares a surface.

Every acceptance criterion in a work-item `spec.md` (or a Standard-lane `JOURNAL.md`) MUST follow this format:

```
**AC-<N>** (surfaces: <CSV>): <body>
```

- **`AC-<N>`** — monotonic integer identifier, never reused within a spec.
- **`(surfaces: <CSV>)`** — comma-separated list of surface tokens, drawn from the fixed vocabulary:
  - `CLI` — behavior exposed through a command-line subcommand / handler
  - `HTTP` — behavior exposed through an HTTP route / endpoint
  - `MCP` — behavior exposed through an MCP tool
  - `RENDER` — a terminal / display / formatting path
  - `DB` — a direct database read / write or a database invariant
  - `EVAL` — a measured quality threshold over a frozen golden dataset (Eval-Driven Development); the "handler" is the golden-dataset file declared in the plan matrix
  - `none` — internal-only behavior (calculation, invariant, helper)
- **`<body>`** — Given/When/Then or imperative prose. Single paragraph.

A project uses whatever **subset** of this vocabulary applies to it: a pure CLI tool uses `CLI, none`; a web service uses `HTTP, none`; a tool that exposes the same operation through several entry points lists them all (`CLI, HTTP, MCP`). The vocabulary is fixed so the parser and audit only ever reject *typos*, never legitimate surfaces — you never declare an enum per project.

## Why this format exists

LCD's Deep-lane test-generation phase (`/lcd:test-gen`) parses these declarations to emit one failing test per (AC × surface). The audit phase (`/lcd:audit`) parses the same declarations to verify every declared surface has a corresponding handler AND a passing test. The format is the contract between phases.

If a spec uses `1.`, `2.` ordinals without an explicit `(surfaces: ...)` tag, both phases fail closed.

Worked examples live at their point of use in `/lcd:test-gen` (the phase that parses them);
the EVAL-coverage guidance (when an EVAL AC is required, the must-not rule) lives in
`/lcd:specify` (the phase that writes ACs).

## Surface token rules

- Use `none` when the AC describes pure-internal behavior (a helper function, an invariant, a calculation). Do not use `none` together with other tokens.
- Use `EVAL` when the AC promises a measurable quality bar over a frozen golden dataset (e.g. "calibration MAE stays ≤ 0.15 on the reference set"). `none` combines with nothing; `EVAL` is **mixable** with any real surface (e.g. `MCP, EVAL` when an eval guards a tool's output) — but, like every token, never with `none`. The plan matrix row for an `EVAL` AC points at the golden-dataset file; test-gen emits the eval into the project's test tree; the audit confirms the dataset file exists. Non-deterministic evals (e.g. an LLM call) must `skipIf` a missing API key so they don't gate keyless CI.
- `RENDER` and `CLI` are distinct: `CLI` covers the subcommand handler; `RENDER` covers the formatter that produces display output. An AC might apply to one but not the other.
- `DB` is only used when the AC promises a direct DB invariant (e.g. "every row in `accounts` has a non-null `owner_id`"). DB writes that happen as a side effect of a CLI/HTTP/MCP call are covered by those surfaces.

## Linkbacks

- `plan.md`'s Cross-path behavior matrix has one row per non-`none` (AC × surface) pair.
- `tasks.md`'s Linkbacks section uses `AC-N → T-X` references.
- Generated test names carry the literal string `AC-N (SURFACE)` (in the test name for JS/TS, in a docstring or id for pytest, in a comment for Go/Rust) — that literal is what the audit greps for.
