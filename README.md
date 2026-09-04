# Lean Context Development (LCD)

LCD is a Claude Code plugin that scores each piece of work and routes it to a Quick, Standard, or
Deep process lane — so light work stays light and heavy work stays organized and resumable. It's for
developers using Claude Code agentically who find full spec-driven pipelines too heavy for most
changes.

Ask for a change and you see one triage line before anything else happens:

```
LCD → Quick (0 signals): no artifacts. Single-file tweak, reversible.
```

The thesis behind that routing is context economy: treat what's in front of the model as a budget to
spend, not a window to fill. A 1M-token window doesn't retire that — cost, prompt-cache TTL,
attention over long context, and cross-session resumability all still bite (no window survives
`/clear` or a new session; only durable artifacts on disk do), so process weight adapts to the work
and a durable spine makes a reset cheap. Current models do better given a durable place to write
learnings and a task spec up front — which is what LCD's artifacts are. See [`docs/why-lcd.md`](docs/why-lcd.md)
for the full argument.

> **Why LCD?** Full spec-driven pipelines are excellent but too heavy for most changes. LCD keeps
> that rigor as one *lane* you earn — not the default. The guiding test for everything it does:
> *spend the minimum process the work actually needs.*

New to LCD? Start with [`examples/quickstart.md`](examples/quickstart.md) — onboard a project, then a
Quick change and a Deep feature end to end.

## The three lanes

A single front door (`/lcd:triage`) scores the work on six signals and routes it:

| Lane | When | What you get |
|---|---|---|
| **Quick** | 0–1 signals — a one-sitting change | No artifacts, no ceremony. Implement directly (TDD still applies). |
| **Standard** | 2–3 signals — may span a session | One resumable `JOURNAL.md`: granular STEPS, edit boundary, TDD, optional inline ACs. |
| **Deep** | Any hard trigger — architecture / parallel surfaces / EVAL / irreversibility — or 4+ signals *with a risk signal among them* | The full pipeline: `spec → plan → tasks → test-gen → red-green → audit`, with a cross-path coverage gate. |

Signals: files touched · architecture impact · surfaces · reversibility · cold-pickup plausibility ·
silently-wrong risk. Ties round **down** — when in doubt, the lighter lane. Routing for 4+ is
risk-gated: without the risk signal (multi-session cold-pickup — Deep-level irreversibility is
already a hard trigger), pure signal accumulation **caps at Standard** — file count alone never
buys the heavy pipeline.

## Durable spine

- **`MAP.md`** — project guardrails (zones, surfaces, invariants); read first on a cold start.
- **`DECISIONS.md`** — append-only decision log (broader than ADR).
- **`work/<slug>/JOURNAL.md`** — per-work-item resume anchor; the fenced `lcd-resume:v1` block is the
  entire cold-start payload, so `/lcd:resume <slug>` rebuilds context from a small anchor (target ~2k tokens).
- **`SPEC.md`** — opt-in fourth artifact (off by default): a living current-state index of what the
  system does now, the behavioural counterpart to MAP's structure. Closed work-items fold into it at
  closeout, so current behaviour isn't something you reconstruct by replaying the work-item chain.

## Requirements

- Claude Code (CLI or desktop).
- Any recent Claude model — no specific model required.
- No build step and no other dependencies; the plugin ships everything its lanes need.

## Install

From the marketplace:

```
/plugin marketplace add stid/lcd
/plugin install lcd@lcd
```

Or run it locally from a checkout without a marketplace:

```
claude --plugin-dir /path/to/lcd
```

Then, in any project:

```
/lcd:onboard      # one-time: writes MAP + DECISIONS + conventions + a CLAUDE.md pointer
```

…and just start working — `lcd:triage` auto-routes new work to the right lane.

## Structural, not just instructed

Where the harness offers a primitive, LCD uses it instead of prose (all hooks **fail open** —
they can never break an un-onboarded project):

- **Edit boundary (PreToolUse hook)** — while a work-item is active on the current branch, edits
  outside its declared EDIT BOUNDARY are denied at the tool layer, with the fix named. Scope: it
  sees `Edit`/`Write` tool calls only — a file changed through the `Bash` tool (sed, heredocs)
  passes it, so on a Bash-first session the boundary is a nudge, not a wall.
- **Cold start (SessionStart hook)** — ~10 lines injected per session: artifact root, MAP, active
  work-items with next actions. Resume happens even if nobody asks for it.
- **Anchor freshness (Stop hook)** — finishing with a stale JOURNAL is blocked once, so the next
  session resumes from reality.
- **Named agents** (`lcd-recon` / `lcd-implementer` / `lcd-reviewer` / `lcd-evaluator`) — the
  fan-out roles ship as definitions with restricted tools and baked-in digest contracts.
  `lcd-evaluator` is the opt-in independent checker (`closeout-evaluator: on`): a fresh context
  that tries to refute a work-item's green suite at closeout, because the session that wrote the
  code shouldn't get the last word on whether it's done.
- **CI audit gate (opt-in at onboarding)** — a vendored GitHub Actions workflow enforces the
  cross-path audit on PRs for every contributor, not just well-behaved sessions.

## Self-measuring

LCD's skills are prompts, so their quality is model-behavioral — measured, not asserted. The
plugin ships its own benchmark: [`evals/run-eval.sh`](evals/run-eval.sh) drives a full non-interactive
Deep-lane run against a frozen fixture and a chosen plugin variant, and a golden-locked grader
emits one comparable result row per run (audit outcome, suite state, build-loop commits, token
cost; rows compare only within one model id). Measured so far (`evals/results.md`, n=3 per arm,
one fixture, `claude-fable-5-1`, 2026-09): the Deep pipeline costs ~4.2× a bare agent and the
median Standard lane ~2.4× (independent closeout evaluator included), at parity single-shot
quality on a persisted rubric (`evals/quality/`) — process weight buys resumability, not
single-shot quality; the evaluator caught real defects the green suite missed in 3 of 6 plugin
runs; the cross-session half is the open measurement (longitudinal eval planned). Prompt
changes ship with an eval row as evidence,
and A/B arms have decided real design questions — step enumeration was dropped from three phase
commands and kept in `test-gen` on measured cost and quality, not taste. A 2026 survey of
spec-driven frameworks (arXiv 2606.04967) names the absence of process benchmarks as a
field-wide gap; LCD's harness is its answer for its own process.

## Learn more

- [`docs/why-lcd.md`](docs/why-lcd.md) — the idea behind LCD and its eight pillars.
- [`docs/vs-sdd.md`](docs/vs-sdd.md) — how LCD differs from spec-driven development tools.
- [`docs/monorepos.md`](docs/monorepos.md) — one spine, zone-scoped toolchains.
- [`examples/brownfield.md`](examples/brownfield.md) — adopting LCD in an existing repo.
- [`rules/lcd.md`](rules/lcd.md) — the full methodology reference.

## Commands & skills

Skills (model-invoked): `triage`, `onboard`, `recon`, `refine`, `redgreen-loop`, `reconcile`
(folds a closed work-item's acceptance criteria into the living `SPEC.md` at closeout).
Commands (Deep-lane pipeline + upkeep): `specify`, `plan`, `tasks`, `test-gen`, `audit`,
`resume`, `tidy`, `doctor`.
All namespaced under `lcd:` (e.g. `/lcd:plan`).

## Self-contained

LCD **bundles** the rules its lanes depend on (`testing`, `no-overengineering`, `no-downgrade`,
`refinement-protocol`, `versioning`, `commits`, `ac-convention`) so it works on any project without
relying on your machine's global config. A project may override any rule with its own
`.claude/rules/<name>.md`.

The project-side artifacts (MAP, DECISIONS, JOURNAL, SPEC) are plain Markdown and tool-agnostic:
if the project has an `AGENTS.md` (the cross-tool agent-instructions standard), onboarding appends
the LCD pointer there too, so non-Claude agents on the team follow the same map and lanes —
AGENTS.md carries the shared layer, CLAUDE.md the Claude-specific one.

## Contributing

Every `bin/` script has a fixture test (`tests/run.sh`, plain bash, seconds); prompt changes are
regression-checked by the eval harness in `evals/`. PR CI is deterministic — eval runs cost API
tokens and happen locally, with the rows pasted into the PR. See
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

[MIT](LICENSE).
