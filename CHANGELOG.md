# Changelog

All notable changes to this project are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/).

Development is tracked by decision IDs (`D-NNN`) in the project's internal decision log; entries
cite them for traceability.

## [0.14.1] — 2026-08-05

### Fixed
- **`tests/helpers.sh` `sedi()` silently dropped the executable bit**: the write-temp + `mv`
  pattern replaced the target file with the temp file's default mode, so any fixture test that
  `sedi`-edited an executable stripped its `+x`. Now cat-over (keeps the target's inode and
  mode). Regression-tested in the new `tests/test-helpers.sh`, which covers the shared test
  lib itself. (Found during the 2026-07 publish run; ported from the dev harness.)

## [0.14.0] — 2026-08-05

The 2026-08 industry-review pass: maker ≠ checker lands as an opt-in closeout evaluator, the
fan-out gate gets its evidence-matched wording, and the eval harness moves to the README front
door. All three changes were themselves gated by an adversarial multi-agent pre-merge review.

### Added
- **Opt-in independent closeout evaluator** (`closeout-evaluator: on` in lcd-conventions, off by
  default): at a Standard/Deep work-item's closeout, after the audit gate passes, the new
  read-only `agents/lcd-evaluator.md` runs in a fresh context and tries to REFUTE the green
  suite — degenerate passes (a test a stub would satisfy), untested AC behaviour, suite-blind
  diff hunks, invariant violations — returning `file:line`-grounded findings. Advisory: the
  verdict lands in the JOURNAL LOG and in front of the user before any PR; it doesn't reopen
  the audit result. Rationale: maker ≠ checker is the current verification consensus — an agent
  judging its own work confidently praises it, and test passage alone can't distinguish a
  correct implementation from a degenerate one. The gate stays mechanical; this is the
  independent semantic half, priced as one opt-in subagent call per closeout.
- **README "Self-measuring" section**: documents the eval harness as a first-class property of
  the methodology — golden-locked grader, evidence-in-PR policy, and the A/B arms that decided
  real design questions. Process benchmarks are a named field-wide gap (arXiv 2606.04967);
  LCD publishes its own.

### Changed
- **Fan-out gate sharpened to test-independence.** The Deep-lane fan-out guardrail gated on
  the surfaces being genuinely independent, defined as disjoint boundaries; disjoint file boundaries don't prove
  the *work* is independent. The gate is now literal: fan out only when the committed baseline's
  failing tests partition the work — each surface's `AC-N (SURFACE)` tests passable without
  touching another surface's boundary. Matches the published evidence on when parallel
  implementers work (independent failing tests) vs. degrade (agents re-solving one shared
  problem). `skills/triage/SKILL.md` + `references/fanout.md`; wording only, no mechanics change.

### Fixed
- **README lane table stated the wrong Deep-routing rule.** It read "4+ signals, or architecture /
  parallel surfaces / EVAL / irreversibility", i.e. the pre-risk-gate rule where soft-signal
  accumulation alone reaches Deep. The implementation (`skills/triage/SKILL.md`), `rules/lcd.md`,
  `docs/why-lcd.md` (pillar 5) and `docs/vs-sdd.md` all specify risk-gated routing: any hard
  trigger → Deep, otherwise 4+ → Deep only when a risk signal (irreversibility or multi-session
  cold-pickup) is among them; pure accumulation caps at Standard. The front door was telling
  readers to over-route the exact case LCD exists to keep light.
- **Stale install conditional**: "Once published to a marketplace" → "From the marketplace"
  (LCD is published).

## [0.13.1] — 2026-07-21

Publish-polish: the doc-accuracy pass from the publish-readiness review. No behaviour change.

### Fixed
- **README front door**: opens with plain identity, audience, and a concrete triage example;
  new Requirements section; `reconcile` and `SPEC.md` added to the skills/spine inventories
  (both shipped but were undocumented); quickstart positioned as the entry point.
- **Phantom `verify` verb removed**: the Deep pipeline is six steps everywhere again
  (`rules/lcd.md` verbs list and the triage diagram carried a seventh `verify` step that no
  shipped skill implements); the UI-confirmation point is now a note on the RENDER path via
  the `claude-in-chrome` MCP, and the one-use `build` alias for `redgreen-loop` is gone.
- **Examples accuracy**: onboarding described as it behaves (one interaction, up to three
  questions); "Constitution check" glossed at first use.
- **Uncited numbers softened to plain causal claims**: the `~30%` tokenizer figure,
  "measurably better", and the `80–90%` small-change share.
- **Changelog scrubbed** of references outsiders cannot resolve (private project names, bot
  attributions), with an orientation note for `D-NNN` decision IDs.

### Added
- **`SECURITY.md`** — reporting via GitHub private vulnerability reporting; scope notes for
  the fail-open hook design and the no-model-calls CI.

## [0.13.0] — 2026-07-21

Subtree self-sufficiency (D-020): the plugin tree now carries everything the published repo
needs to accept contributions.

### Added
- **`tests/`** — the fixture-test suite for every `bin/` script moved into the plugin tree,
  with its own `run.sh`; the tree runs its suite standalone.
- **`.github/workflows/ci.yml`** — deterministic CI for the published repo (fixture tests,
  manifest lockstep, `claude plugin validate`); no CI job calls a model API.
- **`.github/workflows/eval.yml`** — maintainer-only manual eval run (`workflow_dispatch`,
  requires the `ANTHROPIC_API_KEY` secret, which fork PRs never receive).
- **`evals/`** — the prompt-regression benchmark (runner, golden-locked grader, frozen
  fixture, variants) now ships with the plugin as local-first tooling; throwaway workspaces
  default to a temp dir. CONTRIBUTING documents the evidence-in-PR eval policy.

## [0.12.1] — 2026-07-20

Audit-gate hardening. Three findings from an automated review of the gate's first
downstream install (a TypeScript project), fixed at the source so future onboards
vendor the corrected scripts.

### Fixed
- **`bin/audit-crosspath.sh` `test_hit()`**: the repo-wide grep for the literal
  `AC-N (SURFACE)` could match the work-item's own `tasks.md` checklist lines, letting a
  checklist-only AC report OK with no real test. Matches under the LCD artifact tree
  (parent of `LCD_SPECS_DIR`) are now excluded. Regression-tested (decoy `tasks.md`).
- **`bin/audit-crosspath.sh` `registry_hit()`**: plan.md path cells are PR-modifiable
  content but were used unsanitized in the file-exists check and grep; cells starting
  with `/` or containing `..` are now rejected. Regression-tested.
- **`templates/ci/lcd-audit.yml`**: the unquoted `for slug in $slugs` loop word-split a
  slug containing a space into fragments that each skipped as "not Deep-lane" — a silent
  audit bypass. Replaced with a newline-safe `while IFS= read -r` loop.

## [0.12.0] — 2026-07-20

Follow-up industry scan (D-019), incremental on 0.11.0's alignment pass: skill-authoring
brought in line with the Agent Skills progressive-disclosure standard, plus a fan-out cost
guardrail. No new skills, commands, or hooks.

### Added
- **Triage fan-out cost guardrail** (D-019): the Deep lane now states when NOT to fan out —
  fan-out must earn its token multiple (genuinely independent surfaces, at least two
  individually substantial); everything else stays in-session.
- **Onboard sizing note** (D-019): always-loaded agent files (CLAUDE.md/AGENTS.md) stay small
  and hand-maintained — append the ~12-line LCD pointer, never auto-generate beyond it.

### Changed
- **Triage fan-out mechanics extracted to a bundled reference** (D-019, progressive
  disclosure): worktree dispatch, Workflow variant, digest contract, and reconcile procedure
  moved verbatim from `skills/triage/SKILL.md` to `skills/triage/references/fanout.md`, read
  at the moment of fan-out. Triage co-loads on every non-trivial work start; the rare
  Deep+fan-out path no longer taxes it. Skill-description audit against
  description-as-trigger guidance: all six already compliant, verified not changed.

## [0.11.1] — 2026-07-08

### Fixed
- **Standard-lane audit path defined** (D-018): triage's Standard lane pointed surface-declaring
  items at `/lcd:audit`, but `audit-crosspath.sh` refuses without Deep's `spec.md`+`plan.md`.
  `commands/audit.md` now defines the Standard exception — the test-presence check (every inline
  `AC-N (SURFACE)` has a passing test carrying that literal token, suite green), no script run,
  result in the JOURNAL LOG, closeout `audit: PASS (test-presence)`. The script stays Deep-only:
  without a plan matrix there is no handler column to check.

## [0.11.0] — 2026-07-08

The industry best-practice alignment pass: a two-agent review (repo map + 2025–mid-2026
industry research, primary sources) confirmed LCD's core bets and closed the gaps it found.
Every closure is a doc line, a template field, a one-cell marker, or a row stamp — no new
skills, commands, or hooks (D-017).

### Added
- **Quick-lane SPEC staleness marker** (D-016, narrows D-014's known boundary): when
  `living-spec: on` and a Quick change alters behaviour already indexed in `SPEC.md`, the
  affected row's Provenance cell gains `· stale: <date>` — a one-cell marker, not a fold
  (folding stays Standard/Deep-only). `reconcile` clears the marker on the next fold of that
  capability; `/lcd:tidy` reports lingering markers. The index flags its own lag instead of
  silently lying where LCD's thesis says most work happens.

### Changed
- **AGENTS.md layering stance made explicit** (D-017, extends D-006): AGENTS.md — now the
  cross-tool standard for agent instructions — carries LCD's shared tool-agnostic layer (onboard
  already appends the pointer there), CLAUDE.md the Claude-specific layer. Onboard and README
  say so; onboard still never creates an AGENTS.md unprompted.
- **In-flight decision capture** (D-017): the DECISIONS template and `rules/lcd.md` now say
  entries are written at the moment of choice (with the alternatives actually weighed), not
  backfilled at closeout.
- **Philosophy docs grounded in primary sources**: `why-lcd.md` and `vs-sdd.md` cite Anthropic's
  context-engineering guidance (attention budget, context rot, progressive disclosure) and Kent
  Beck's spec-first critique (via Martin Fowler) — the sources the pillars independently
  converged with — plus the Spec Kit ecosystem's own drift tooling as confirmation of the
  living-spec problem.

## [0.10.0] — 2026-06-27

### Added
- **Living-spec backfill for existing projects.** 0.9.0's `reconcile` is forward-only (folds at
  closeout), so enabling `living-spec` on a *mature* project produced an empty `SPEC.md` that only
  filled as new work closed — it didn't represent existing behaviour. Adoption now backfills:
  `/lcd:onboard` (retrofit) injects the `spec`/`living-spec` keys into an existing conventions
  block and, on enable, **generates an initial `SPEC.md` from MAP + the actual surfaces** at
  **capability-group altitude** (one row per cluster — a 20-tool MCP server or a 38-route API is a
  few grouped rows, not one-per-item — to honour MAP's "a map, not documentation" discipline).
  Backfilled rows are a lower-confidence tier: `D-NNN (backfill)`, code-derived and **not**
  AC-verified, that **decay into rigor** — `reconcile` supersedes each with a real AC-pinned `D-NNN`
  the next time a work-item touches that capability. Rationale in D-014; first applied to
  a downstream TypeScript project.

## [0.9.0] — 2026-06-27

### Added
- **Living current-state spec (`SPEC.md`) + `lcd:reconcile` compaction.** LCD inherited
  spec-driven development's living-spec limitation: change was tracked as a chain of frozen
  per-work-item specs plus append-only logs, with no single document for "what the system does
  now" — you reconstructed it by replaying the chain. New optional third truth tier: `work/<slug>/
  spec.md` (frozen delta) · `DECISIONS.md` (append-only history) · **`SPEC.md`** (living
  current-state capability index, current-only). The `reconcile` skill folds a closed work-item's
  ACs into `SPEC.md` at closeout (audit PASS / Standard done), reusing `parse-acs.sh` unchanged.
  **Opt-in** (`living-spec: off` by default) — Quick lane and existing projects behave exactly as
  before. `triage` reads the relevant `SPEC.md` surface section when scoping Standard/Deep work;
  `onboard` offers to enable it; `lcd-doctor.sh` warns when it's on but `SPEC.md` is missing.
  Deliberately **not** bidirectional and **not** a CI drift-gate. Rationale in D-012; the
  living-spec problem and LCD's answer are written up in `docs/vs-sdd.md`. Template is
  `templates/living-spec.md` (named to dodge a case-insensitive-FS collision with the work-item
  `templates/spec.md`).

## [0.8.0] — 2026-06-19

### Changed
- **EVAL surface gains must-not guidance** (`rules/ac-convention.md`, `templates/spec.md`): for
  paths whose output can be silently wrong (LLM output, scorers, rankers), authors are now asked to
  pin an explicit **must-not / forbidden behavior** alongside the positive criterion — the failure
  that embarrasses you is usually the presence of a bad trait, not the absence of a good one, and a
  purely positive Given/When/Then can pass while the output is still unacceptable. Expressed through
  the existing AC format (negative AC body or a companion negative-bodied AC) — deliberately **not**
  a new `must-not:` field, so `parse-acs.sh`/`test-gen`/`audit` are unchanged. Prompted by the
  "evals not PRDs" article's `fail_criteria` pattern; rationale in D-011.

## [0.7.0] — 2026-06-11

The improvement-queue pass: close the outcome-measurement loop, cover the compaction reset,
make prompt quality measurable — then use the measurement.

### Changed
- **Deep-lane phase commands de-prescribed** (`specify.md`, `plan.md`, `tasks.md`): numbered
  step enumeration replaced by goal + constraints ("order your own steps; the gates and
  constraints are the contract"). Gates, artifact contracts, the AC format, JOURNAL sync, and
  "What NOT to do" phase boundaries are unchanged; `test-gen`/`audit`/`redgreen-loop` stay
  step-wise (machine contracts). Decided by the planned A/B (D-009): 3 runs/arm on the frozen
  benchmark — exact quality parity (6/6 audit PASS first try, 6/6 suite green), arm-B mean
  tokens ~3% lower (within noise). The step scaffolding was not load-bearing for quality.

### Added
- **Outcome telemetry (closeout lines).** The triage log recorded which lane an item *got*;
  nothing recorded whether the lane was *right*. Standard/Deep work-items now append a one-line
  **closeout** to `<artifact-root>/triage-log.md` at their finish line
  (`date · work · closeout · lane · audit · re-routes · red-green iters · interventions`):
  the audit command writes it on PASS, the red-green loop records its iteration count in the
  JOURNAL LOG to feed it, and `/lcd:tidy` reads triage + closeout lines against each other
  to flag **under-routing** (escalated items) and **over-routing** (Deep items that sailed
  through first try) plus closeout coverage. Quick lane stays closeout-free — its triage line
  is its whole trace. Lane thresholds become data-tuned instead of asserted.
- **Prompt eval harness (dev repo).** The skills are prompts — quality is model-behavioral, and
  until now a rewording could silently degrade Deep-lane output with no regression signal.
  `evals/` (dev level, not shipped) adds a one-command benchmark: a frozen pre-onboarded
  sandbox fixture + a frozen 2-surface scripted feature, one non-interactive Deep-lane run per
  invocation against a chosen `--plugin-dir` variant, graded mechanically (audit gate, suite,
  commit counts, tokens) and golden-locked (`evals/golden/`). A/B experiments (e.g. the
  de-prescription experiment) are now repeated invocations + a read of `evals/results.md`.
  Prereq for safely accepting post-publish PRs that reword skills. Both planned experiments
  ran the same day: specify/plan/tasks de-prescription adopted (D-009, corrected by D-010 to
  "cost parity, quality parity"); the `test-gen` follow-up **rejected** by the same harness
  (quality parity but ~11–14% cost regression — D-010), demonstrating the benchmark can say
  no. Grader metric v2: `modelUsage` volume (subagent-inclusive, scheduling-invariant) + cash
  cost.
- **Compaction-reset coverage.** LCD guarded fresh sessions (SessionStart) and the finish line
  (Stop) but not **compaction** — the most common in-session reset. `lcd-session-context.sh`
  now reads the SessionStart payload's `source`: on `"compact"` it injects a richer resume
  spine (trust-the-JOURNAL note + each active work-item's EDIT BOUNDARY on top of lane/next
  action), because the compaction summary isn't guaranteed to carry it. PreCompact itself has
  no context-injection channel (output contract is block/allow only), so the post-compaction
  SessionStart is the structural injection point — D-008. Fail-open as always; fixture-tested.
- **/loop recipes (docs only — harness feature, never a dependency).** Fan-out monitoring
  (generous-interval digest checks while background implementers run) in the `triage` SKILL,
  and a maintenance cadence in `/lcd:tidy`. Both note: prefer event-driven signals;
  `/loop` fills the gaps between events.

## [0.6.0] — 2026-06-11

Fable 5 leverage pass + publish-prep hardening (follow-up to the open-source-readiness audit).

### Added
- **Onboard appends the LCD pointer to an existing `AGENTS.md`** (the cross-tool agent
  instructions file read by Cursor and others) so non-Claude agents on a team get the artifact
  map and lane discipline too. It never creates the file — only extends one the project already
  uses.
- **`scripts/prep-publish.sh` hardened (dev repo):** the identity scrub (plugin.json author,
  marketplace.json owner, LICENSE copyright holder) and the README repo-slug stamp are now
  automated in `--apply`; the subtree-split publish flow (D-007) is encoded in the header and
  checklist; fixture test `tests/test-prep-publish.sh` covers dry-run purity, dirty-tree
  refusal, and the full apply path.

### Changed
- **Fable 5 leverage pass.** Every skill/command/agent description now leads with its trigger
  condition (the newest model tier under-reaches for capabilities whose descriptions only say
  *what*, not *when*). Deep-lane fan-out guidance is now **async**: worktree-isolated
  implementers run in the background while the orchestrator preps reconciliation and intervenes
  on off-track digests (worktree isolation and merge-based reconciliation unchanged).
  Conservative de-prescription sweep over shouty imperatives; load-bearing guards (fail-open
  hooks, edit boundaries, no-public-push gate) kept intact. Premise docs note that a ~30%
  denser tokenizer raises the cash value of context economy and that LCD's durable artifacts
  double as the memory surface / cold-start payload newer models are documented to benefit
  from. Structural de-prescription of the Deep pipeline is **deferred** to a defined A/B
  experiment (`docs/lcd/work/fable5-leverage/experiment-deprescription.md`).

## [0.5.0] — 2026-06-10

Make the guarantees structural, the adoption frictionless, and the plugin itself tested.

### Added
- **Hooks (`hooks/hooks.json`) — all fail-open.** PreToolUse `lcd-boundary-check.sh` denies edits
  outside an active work-item's EDIT BOUNDARY (the single-agent counterpart of worktree isolation);
  SessionStart `lcd-session-context.sh` injects artifact-root + active work-items with next actions
  (automatic cold pickup); Stop `lcd-staleness-check.sh` blocks finishing once when the resume
  anchor predates the last commit.
- **Named agents (`agents/`).** `lcd-recon` (read-only research, digest contract baked in),
  `lcd-implementer` (boundary + change-manifest contract), `lcd-reviewer` (cross-surface review).
  The recon/triage skills now dispatch them by name instead of re-prompting the roles.
- **`/lcd:doctor`** (`lcd-doctor.sh`): executable health check of the conventions machine
  block — placeholders, watch-mode commands, artifact presence, CLAUDE.md pointer, placement vs
  discovery glob, ac-convention override. Onboard runs it as its quality gate.
- **CI audit gate (opt-in at onboarding):** `templates/ci/lcd-audit.yml` + vendored audit scripts
  under `<root>/ci/` — the cross-path audit blocks PRs for every contributor.
- **Monorepo support:** zone-scoped machine-block keys (`key[<path-prefix>]:`, longest prefix
  wins) honored by the red-green loop and test-gen; `docs/monorepos.md`.
- **`examples/brownfield.md`** — adopting LCD in an existing repo.
- **Test suite for `bin/`** (dev repo): plain-bash fixture tests for parse/audit/doctor and all
  three hooks, plus a CI workflow (tests, manifest sanity, `claude plugin validate`).

### Fixed
- **`ac-convention` never auto-loaded on a non-default artifact root** (its `paths:` only covered
  `docs/lcd`). Onboard now writes a project-local override with globs derived from the chosen
  root; doctor checks for it.
- Doctor's placeholder heuristic no longer flags lowercase substitution tokens (`<slug>`,
  `<surface>`) — only ALL-CAPS template placeholders.

### Changed
- Onboard writes the audit permissions to the **committed** `.claude/settings.json` (team-shared)
  instead of `settings.local.json`; machine-local stays available on request.

## [0.4.0] — 2026-06-06

Make LCD measure itself, and make triage correctable.

### Added
- **Triage telemetry.** Every `triage` now appends one line to `<artifact-root>/triage-log.md`
  (`date · work · n signals · lane · hard · risk`) — the durable trace that lets LCD check its own
  claims (is most work really Quick? is Deep earned?) instead of asserting them. A single shared
  line, not a per-work-item artifact, so Quick lane stays artifact-free. Mirrored in `rules/lcd.md`.
- **Lane-distribution report in `/lcd:tidy`.** Tidy now summarizes the Quick/Standard/Deep split
  from the triage log, and flags **DECISIONS staleness** (commits since `DECISIONS.md` was last
  touched) alongside its existing MAP-drift scan — closing the measurement loop (a log nobody reads
  isn't measurement).
- **Mid-flight lane re-routing.** The `triage` SKILL and `rules/lcd.md` now document how to escalate
  (Quick→Standard→Deep, carrying the work forward) or de-escalate to the lighter lane when the lane
  proves wrong, recording the reason as a `D-NNN`. `refine` fixes steps *within* a lane; re-routing
  fixes the lane itself — triage is no longer a one-shot guess.
- **Explanatory docs** (`docs/why-lcd.md`, `docs/vs-sdd.md`): the idea behind LCD and its
  eight pillars, plus an explicit comparison with spec-driven development tools (GitHub
  Spec Kit). README gains a "Learn more" section linking them.

## [0.3.0] — 2026-05-28

Close the last open triage routing question from the 1M-context repositioning.

### Changed
- **Risk-gated soft-signal accumulation.** Triage Step 2 now distinguishes a *hard trigger*
  (architecture / parallel-surfaces / EVAL / irreversibility) from a *risk signal* (irreversibility
  OR multi-session cold-pickup). A hard trigger still routes to Deep regardless of count; otherwise
  **4+ signals route to Deep only if a risk signal is among them** — pure soft-signal accumulation
  (e.g. "6 small files, local refactor, one-commit revert, may span a session") now **caps at
  Standard** instead of escalating to the full Deep pipeline. Mirrored in `rules/lcd.md`.

### Added
- **Worked-example routing matrix** in the `triage` SKILL — pins the routing edges (incl. the
  previously over-escalated 4-soft-signal case) and serves as the regression anchor for the rule.

## [0.2.0] — 2026-05-28

Leverage Opus 4.8's first-class harness primitives instead of simulating them in prose.

### Changed
- **Native multi-agent fan-out.** Deep-lane parallel surfaces now run each implementer with
  `isolation: "worktree"` — its own branch from the baseline, so a boundary violation is
  *structurally impossible*; the orchestrator reconciles by merging the surface branches. This
  replaces the previous baseline-commit + `git diff --name-only` check (which only *detected*
  violations after the fact).
- **Context-economy premise reframed for the 1M-token window** (`rules/lcd.md`, `README.md`): lanes
  are justified by cost, latency, prompt-cache TTL, attention over long context, and cross-session
  resumability — not "it won't fit."
- **Triage file-count threshold recalibrated** for the 1M era: `3–5 / 6+` → `3–8 / 9+`, with a note
  that file count is a soft cost proxy (never a hard Deep trigger — only architecture, parallel
  surfaces, EVAL, and irreversibility are). No routing downgrade: the Quick line is unchanged.

### Added
- `templates/fanout.workflow.js` — opt-in `Workflow` reference script for large multi-surface
  features: `parallel` worktree-isolated implementers with schema-validated digests, a review stage,
  then the full-suite + audit gate.
- Shared per-surface **change-manifest digest** contract (in `triage` SKILL), schema-validated on the
  Workflow path; `recon` digest gains a schema shape for the same path.
- **Budget-aware** `redgreen-loop` variant when run under a `Workflow` (guards on
  `budget.remaining()`); the in-loop skill keeps the 20-iteration cap + stuck detection unchanged.

## [0.1.0] — 2026-05-26

Initial release as a Claude Code plugin.

### Added
- Three-lane triage front door (`/lcd:triage`) routing work to Quick / Standard / Deep.
- Project onboarding (`/lcd:onboard`): MAP, DECISIONS, conventions, CLAUDE.md pointer.
- Deep-lane pipeline commands: `specify`, `plan`, `tasks`, `test-gen`, `audit`, `resume`, `tidy`.
- Skills: `recon` (current-best-practice grounding), `refine` (autonomous drift correction),
  `redgreen-loop` (autonomous TDD loop).
- Durable artifacts: `MAP.md`, `DECISIONS.md`, per-work-item `JOURNAL.md` with the `lcd-resume:v1`
  cold-start block.
- Cross-path coverage audit (`bin/audit-crosspath.sh`) + AC parser (`bin/parse-acs.sh`).
- Bundled, self-contained rules: `testing`, `no-overengineering`, `no-downgrade`,
  `refinement-protocol`, `versioning`, `commits`, `ac-convention` — overridable per project.
