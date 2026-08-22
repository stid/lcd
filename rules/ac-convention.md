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

## Examples

```
**AC-1** (surfaces: CLI, HTTP, MCP): Given a config key is set in the environment, when any path resolves that key, then the environment value is used.

**AC-2** (surfaces: HTTP): Given /api/doctor is called, when the env-var source supplies the key, then the response includes a `key_source` field set to "env".

**AC-3** (surfaces: none): The resolver returns the first non-empty source in the precedence chain (env → config file).

**AC-4** (surfaces: EVAL): Given the frozen reference set, when the scorer's calibration error is measured, then the mean absolute error stays at or below the declared threshold.

**AC-5** (surfaces: EVAL): Given the frozen counter-example set, when the assistant answers a wrong-item complaint, then the response does NOT emit a raw policy paragraph and does NOT ask for information already supplied in the message.
```

`AC-5` is the must-not companion: same EVAL format, body phrased as a forbidden behavior, scored against counter-examples in the golden dataset.

## Surface token rules

- Use `none` when the AC describes pure-internal behavior (a helper function, an invariant, a calculation). Do not use `none` together with other tokens.
- Use `EVAL` when the AC promises a measurable quality bar over a frozen golden dataset (e.g. "calibration MAE stays ≤ 0.15 on the reference set"). `none` combines with nothing; `EVAL` is **mixable** with any real surface (e.g. `MCP, EVAL` when an eval guards a tool's output) — but, like every token, never with `none`. The plan matrix row for an `EVAL` AC points at the golden-dataset file; test-gen emits the eval into the project's test tree; the audit confirms the dataset file exists. Non-deterministic evals (e.g. an LLM call) must `skipIf` a missing API key so they don't gate keyless CI.
- `RENDER` and `CLI` are distinct: `CLI` covers the subcommand handler; `RENDER` covers the formatter that produces display output. An AC might apply to one but not the other.
- `DB` is only used when the AC promises a direct DB invariant (e.g. "every row in `accounts` has a non-null `owner_id`"). DB writes that happen as a side effect of a CLI/HTTP/MCP call are covered by those surfaces.

## EVAL coverage (when an EVAL AC is required)

A spec that changes a path whose output can be **silently wrong** — a scorer, a ranker, a recommender, any LLM-generated output — SHOULD include at least one `EVAL` acceptance criterion, OR `plan.md`'s constitution check should state why an eval isn't warranted. Quality regressions in these paths are silent ("plausible but wrong"), so they need a measured gate (error metric, tolerance band, regression bound), not just a presence test. Features with no quality dimension (CRUD endpoints, CLI flags, render tweaks) do not need an EVAL AC. The golden-dataset and the metric harness are **project-local and opt-in** — the framework only asks that the AC name a measurable threshold over a frozen dataset.

State the **must-not** too. For LLM-output / scorer / ranker paths the forbidden behavior is often the load-bearing half of "good" — the failure that embarrasses you is rarely the absence of a positive trait, it's the presence of a bad one (leaks a raw policy paragraph, re-asks for information already supplied, fabricates a citation). A purely positive Given/When/Then ("acknowledges the issue") can pass while the output is still unacceptable. So an `EVAL` AC over a silently-wrong path SHOULD pin at least one explicit must-not / forbidden behavior, phrased *within the AC body* ("…, then the response does NOT do X") or as a **companion negative-bodied AC** — using the ordinary AC format, **not** a new field. The golden dataset then carries the counter-examples (inputs paired with a response that would fail), so the measured gate scores the must-not, not just the must.

## Linkbacks

- `plan.md`'s Cross-path behavior matrix has one row per non-`none` (AC × surface) pair.
- `tasks.md`'s Linkbacks section uses `AC-N → T-X` references.
- Generated test names carry the literal string `AC-N (SURFACE)` (in the test name for JS/TS, in a docstring or id for pytest, in a comment for Go/Rust) — that literal is what the audit greps for.
