# Lean Context Development (LCD) — methodology reference

> On-demand reference (no `paths:` frontmatter, so it is **not** always-loaded). The always-on
> trigger lives in each onboarded project's `CLAUDE.md` (a ~12-line pointer written by
> `/lcd:onboard`). This file is the full picture for when you need it.

## Defining principle

**Context is the first-class scarce resource — and a large window doesn't change that.** Even with a
1M-token window the binding constraints are *cost* (you pay per token, every turn), *latency* (big
prompts are slower), *prompt-cache misses* (churning context falls out of cache; TTLs vary by plan and load), *attention*
(recall degrades across very long context), and — the one a bigger window can't touch — *cross-session
resumability* (no window survives `/clear` or a new session; durable artifacts do). So lanes are
justified by cost and resumability discipline, not by "it won't fit." Process weight adapts to the
work, and durable artifacts make a context reset cheap. Coverage correctness (the cross-path audit)
is preserved — but subordinated to context economy: the heavy pipeline is one *lane*, not the default.
The newest model tier sharpens both halves: a denser tokenizer raises the per-token price of bloat,
and the same models do better with a durable memory surface plus a full task spec served up front
on a cold start — exactly the role of MAP / DECISIONS / JOURNAL.

## Three lanes (chosen by `lcd:triage`)

Score six signals; route by the count, rounding ties **down**:

| Signal | Quick | Standard | Deep |
|---|---|---|---|
| Files touched | 1–2 | 3–8 | 9+ |
| Architecture impact | none | local | new module · cross-cutting · new dependency |
| Surfaces | 0–1 | 1, or 2 sharing one path | 2+ parallel, or any EVAL |
| Reversibility | trivial | one-commit | schema / migration / public API |
| Cold-pickup | one sitting | may span a session | multi-session |
| Silently-wrong risk | none | low | scorer/ranker/LLM-output → EVAL |

0–1 → **Quick** · 2–3 → **Standard** · **any hard trigger** (Deep-column hit on architecture / parallel surfaces / EVAL / irreversibility) → **Deep**. Otherwise **4+ → Standard, UNLESS the *risk signal* — multi-session cold-pickup — is among them → Deep** (Deep-level irreversibility is already a hard trigger, so it never reaches this branch): pure soft-signal accumulation caps at Standard. The user overrides in one word. File count is **not** a hard Deep trigger — post-1M it's a soft cost proxy, not a fit proxy; resumability and the hard triggers carry the routing.

- **Quick** — no artifacts, zero subagents, go direct (TDD still applies). The escape hatch that keeps LCD light.
- **Standard** — one `JOURNAL.md` per work-item: granular resumable STEPS + inline ACs (only if a surface needs the audit) + TDD + verify. No spec/plan/tasks split.
- **Deep** — the full pipeline (`spec → plan → tasks → test-gen → red-green → audit`) under `<root>/work/<slug>/`, with a `JOURNAL.md` above it as resume anchor + phase tracker.

**Telemetry.** Every triage appends one line to `<root>/triage-log.md` (`date · work · n signals · lane · hard · risk`) — the durable trace that lets LCD check its own claims (is most work really Quick? is Deep earned?). It's a single shared line, not a per-work-item artifact, so Quick lane stays artifact-free. Standard/Deep work-items append a **closeout** line at their finish line (`date · work · closeout · lane · audit · re-routes [· red-green iters] · interventions` — the iters field is optional; contract in the triage skill's `references/closeout.md`; both line shapes are written via `lcd-triage-log.sh`, which validates them) — routing records which lane an item *got*, closeout records whether the lane was *right*. `/lcd:tidy` summarizes the distribution and reads the two shapes against each other to flag miscalibrations (escalated items = under-routing; Deep closeouts that sailed through = over-routing), turning lane thresholds from designed constants into data-tuned ones.

**Re-routing.** Triage isn't one-shot. If a lane proves wrong mid-flight, **escalate** (Quick→Standard→Deep, carrying the work forward) or **de-escalate** to the lighter lane, and record the reason as a `D-NNN`. `refine` fixes steps *within* a lane; re-routing fixes the lane itself.

## Durable artifacts

- **`<root>/MAP.md`** — project logical-organization guardrails (zones, surfaces, invariants). Read first on a cold start. On-demand.
- **`<root>/DECISIONS.md`** — append-only, broader-than-ADR decision log. Never rewrite history; supersede. Write entries **in-flight, at the moment of choice** (context is freshest then; a closeout backfill loses the alternatives that were actually weighed).
- **`<root>/SPEC.md`** — optional living current-state spec (a capability index of what the system does *now*). On-demand, read when scoping new work — **not** in the cold-start payload. Exists only when `living-spec: on`; kept current by `reconcile` at closeout. See "Three tiers of truth" below.
- **`<root>/work/<slug>/JOURNAL.md`** — per-work-item resume anchor. The fenced `lcd-resume:v1` block is the entire cold-start payload.

`<root>` = `artifact-root` from `.claude/rules/lcd-conventions.md` (default `docs/lcd`).

### Three tiers of truth (where change lives)

Spec-driven methods tend to track change as a chain of frozen per-change specs plus append-only
logs, leaving no single document for "what the system does now" — you re-derive it by replaying the
chain. LCD splits the concern into three artifacts with different rules, so each stays honest:

- **detail — the frozen delta** (`work/<slug>/spec.md`, or a Standard JOURNAL's inline ACs): what
  one change added; freezes at `implemented`; prunable by `tidy` once compacted.
- **history — append-only** (`DECISIONS.md`): *why* a capability exists or changed; never rewritten.
- **current-state — living index** (`SPEC.md`): what the system does now; current-only (a replaced
  capability is rewritten in place, its history kept in DECISIONS); folded one-way delta → SPEC by
  `reconcile` at closeout.

This is **opt-in** (`living-spec: off` by default) — for a young project the work-item chain *is* the
current state and an index is pure overhead; turn it on once "what does this do now" is expensive to
re-derive. Quick-lane work never *folds* the index, but when it alters an indexed behaviour it
appends `· stale: <date>` to that row's Provenance — a one-cell marker so the index never silently
lies; the next fold of that capability clears it (a stale spec is worse than no spec). `MAP.md` (structure: *where*) and `SPEC.md` (behaviour: *what-it-does*) are different axes
and stay separate files. **Adopting it on an existing project**: `/lcd:onboard` (retrofit) adds
the keys and **backfills** `SPEC.md` once from MAP + code at capability-group altitude — those rows
are a lower-confidence `D-NNN (backfill)` tier (code-derived, not AC-verified) that `reconcile`
decays into AC-pinned rows as work touches them. Forward-only reconcile alone would leave an existing
project's index empty until new work churns through it; the backfill is what makes it represent the
*whole* current state on day one.

## The verbs (skills/commands, used as needed)

- **recon** (`lcd:recon`) — ground in *current* best practice (Context7 + web) before deciding, in a subagent. Standard/Deep only.
- **refine** (`lcd:refine`) — autonomous drift correction of STEPS / tasks / MAP, logged. Bounded by `refinement-protocol`.
- **reconcile** (`lcd:reconcile`) — compaction at closeout: folds a closed work-item's ACs into the living `SPEC.md` (no-op when `living-spec: off`). Standard/Deep only.
- **tidy** (`/lcd:tidy`) — prune stale work-items + run the maintenance bundle.
- **redgreen-loop** (`lcd:redgreen-loop`) — the autonomous TDD loop.
- **audit** (`/lcd:audit`) — the cross-path PR gate.
- **resume** (`/lcd:resume`) — rebuild context in <~2k tokens after a reset.

## Multi-agent rule

The orchestrator never reads bulk content into its own window — it dispatches a subagent, takes a ≤15-line digest, and writes that digest to a durable artifact. Fan-out points: recon, deep-explore, per-surface implementation, review, closeout evaluation (opt-in). Quick lane = zero subagents.

The plugin **ships the agents** for the named roles (`agents/`): `lcd-recon` (read-only research + digest contract), `lcd-implementer` (boundary + change-manifest contract), `lcd-reviewer` (read-only cross-surface review), `lcd-evaluator` (read-only closeout refutation — opt-in via `closeout-evaluator: on`; the session that wrote the code doesn't get the last word on whether it's done). Dispatch those rather than re-prompting the role from prose — the contracts live in the definitions, and their tool lists are restricted to what the role needs.

Parallel per-surface implementers run with `isolation: "worktree"` — each on its own branch from the baseline commit, so a boundary violation is *structurally impossible* (not detected after the fact). The fan-out is **async**: implementers launch in the background and the orchestrator keeps working (reconciliation prep, review setup), checking digests as they land and intervening on an off-track implementer rather than blocking on the slowest surface; then it reconciles by merging the surface branches (disjoint boundaries merge clean). For a large multi-surface feature the **`Workflow`** tool (opt-in) drives the same fan-out deterministically with schema-validated digests — reference script `${CLAUDE_PLUGIN_ROOT}/templates/fanout.workflow.js`, details in the `triage` SKILL.

## Structural enforcement (hooks)

LCD prefers **structural** guarantees over instructed ones (the same instinct as worktree
isolation). The plugin ships hooks (`hooks/hooks.json`), all **fail-open** — an un-onboarded
project, a missing dependency, or an unfilled artifact always means "allow":

- **Edit boundary (PreToolUse).** While a work-item is *active* on the current branch (JOURNAL
  `Branch` matches HEAD and STEPS has unchecked items), edits outside its EDIT BOUNDARY are denied
  at the tool layer — the deny reason points at the fix (`lcd:refine` to extend the boundary,
  logged). The artifact root and `.claude/` stay always-editable.
- **Cold-start context (SessionStart).** Every session in an onboarded project starts with ~10
  injected lines: artifact-root, MAP/DECISIONS paths, and active work-items with lane + next
  action — so resume happens even when nobody types `/lcd:resume`. The same hook covers
  **compaction** (the most common in-session reset): on a `source: "compact"` restart it injects
  a richer spine — trust-the-JOURNAL note + each active item's EDIT BOUNDARY — because the
  compaction summary isn't guaranteed to carry it (PreCompact has no context channel; D-008).
- **Resume-anchor freshness (Stop).** Finishing a turn with an active work-item whose JOURNAL
  `Updated` predates the last commit is blocked once, with instructions to bring NOW/STEPS
  current — a stale anchor lies to the next session, which is worse than none. Same-day
  granularity; never blocks twice in a row.

## Bundled rules (shipped with LCD)

LCD **ships** the rules its lanes depend on, so it works on any project without relying on your
machine's global config. They live in the plugin and are read via `${CLAUDE_PLUGIN_ROOT}/rules/<name>.md`:
`testing`, `no-overengineering`, `no-downgrade`, `refinement-protocol`, `versioning`, `commits`,
plus `ac-convention` (the one with `paths:` frontmatter, so it auto-loads on specs/JOURNALs). The
Deep-lane plan's Constitution check reads them from there. **A project may override any rule** with
its own `.claude/rules/<name>.md` — the project's version wins when present.
