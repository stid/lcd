# Why LCD — the idea and the pillars

This is the long-form companion to the [README](../README.md). It explains the problem LCD
solves, the idea behind it, and the pillars it rests on. For how LCD differs from
spec-driven development tools specifically, see [vs-sdd.md](vs-sdd.md).

## The problem

Two things make agentic development go sideways at scale.

**1. Full spec-driven pipelines are too heavy for most changes.** A `spec → plan → tasks →
implement → audit` pipeline is exactly right for a risky, multi-surface feature — and pure
overhead for a one-file fix. When the pipeline is the *default*, every typo fix carries
ceremony, and the rigor that should signal "this is the dangerous 10%" gets diluted into
noise. Kent Beck's critique of spec-first flows (relayed by Martin Fowler, 2026) adds the
learning-side half of the problem: a spec frozen before implementation "encodes the bizarre
assumption that you aren't going to learn anything during implementation." Adaptive lanes plus
mid-flight re-routing are LCD's answer to both halves — the heavy spec is earned, and
correctable.

**2. Context is the first-class scarce resource — and a 1M-token window doesn't change
that.** It's tempting to think a huge context window retires the problem ("it all fits
now"). It doesn't. The binding constraints were never only about fit:

- **Cost** — you pay per token, every turn. A bloated window is a bloated bill.
- **Latency** — big prompts are slower to process, every turn.
- **Prompt-cache misses** — long, churning context falls out of the cache, so you re-pay
  for tokens you already sent. (Cache TTLs vary by plan and load; the discipline doesn't.)
- **Attention** — recall degrades across very long context; the model attends worse to a
  needle in a 900k-token haystack than to a tight, relevant prompt.
- **Cross-session resumability** — the one a bigger window *can't* touch. No window
  survives `/clear` or a new session. When the context is gone, only durable artifacts on
  disk remain.

These are no longer LCD-private claims. Anthropic's context-engineering guidance names the
same "attention budget," documents **context rot** (recall degrading as context grows,
across all models), and prescribes the moves LCD's spine makes: just-in-time retrieval,
compaction handling, and structured note-taking. LCD's skills also load by **progressive
disclosure** — name and description up front, the full instruction set only when relevant —
the same discipline applied to the methodology's own footprint.

Newer model tiers tilt the math further, not back: a denser tokenizer turns the same
content into more tokens, so context economy is worth more in plain cost terms — and durable
artifacts make a reset cheap because the next session reads a small anchor instead of
replaying the whole history, which is precisely what LCD's artifacts are.

So the question is never "will it fit?" It's "what is the *minimum* the model needs in
front of it to do this turn well — and what must be written down so the next session can
pick up cheaply?"

## The idea

> **Spend the minimum process the work actually needs — and write down exactly enough that
> a cold session resumes cheaply.**

LCD turns that one sentence into a working method with two moving parts:

- **Adaptive lanes.** A single front door (`/lcd:triage`) scores incoming work and
  routes it to one of three lanes — **Quick** (no artifacts), **Standard** (one resumable
  journal), or **Deep** (the full pipeline). Process weight is proportional to risk, not
  fixed. Most work is Quick. The heavy pipeline is one lane you *earn*, not the default.

- **A durable spine.** A small set of on-disk artifacts (`MAP.md`, `DECISIONS.md`, a
  per-work-item `JOURNAL.md`) hold just enough state that a context reset is cheap — a cold
  start rebuilds in roughly 2k tokens instead of by re-reading the whole feature.

Together these mean small work stays fast and large work stays organized and resumable —
without the model ever having to hold more in context than the current turn requires.

## The pillars

### 1. Context economy

Context is treated as a budget to spend deliberately, not a window to fill. Every lane,
artifact, and subagent boundary exists to keep what's in front of the model *small and
relevant*. The justification is cost, latency, prompt-cache TTL, attention, and
resumability — never "it won't fit." Coverage correctness is preserved, but *subordinated*
to context economy: the heavy pipeline is one lane, not the default.

### 2. Adaptive lane weight

Triage scores six signals and routes by the count:

| Signal | Quick | Standard | Deep |
|---|---|---|---|
| Files touched | 1–2 | 3–8 | 9+ |
| Architecture impact | none | local/contained | new module · cross-cutting · new dependency |
| Surfaces (CLI/HTTP/MCP/RENDER/DB/EVAL) | 0–1 | 1, or 2 sharing one path | 2+ parallel, or any EVAL |
| Reversibility | trivial revert | one-commit revert | schema/migration/public API |
| Cold-pickup plausibility | one sitting | may span a session | multi-session / multi-phase |
| Silently-wrong risk | none | low | scorer/ranker/LLM-output → EVAL |

0–1 → **Quick** · 2–3 → **Standard** · routing for 4+ is risk-gated (pillar 5). Ties round
**down**.

- **Quick** — no artifacts, zero subagents, implement directly (TDD still applies). The
  escape hatch that keeps LCD light.
- **Standard** — one `JOURNAL.md` per work-item: granular resumable STEPS, an edit
  boundary, TDD, optional inline acceptance criteria. No spec/plan/tasks split.
- **Deep** — the full pipeline (`spec → plan → tasks → test-gen → red-green → audit`) with
  a cross-path coverage gate.

### 3. Cheap resumability (the durable spine)

Three artifacts make a reset survivable:

- **`MAP.md`** — project guardrails (zones, surfaces, invariants); read first on a cold
  start. On-demand, not always loaded.
- **`DECISIONS.md`** — append-only decision log, broader than an ADR. Never rewrite
  history; supersede.
- **`work/<slug>/JOURNAL.md`** — the per-work-item resume anchor. Its fenced
  `lcd-resume:v1` block (NOW · STEPS · DECISIONS · OPEN QUESTIONS · EDIT BOUNDARY) is the
  *entire* cold-start payload. `/lcd:resume <slug>` rebuilds context from MAP + that
  block + decision headers in under ~2k tokens — not by re-reading the feature.

An optional fourth artifact, **`SPEC.md`** (`living-spec: on`), is a living current-state index
of what the system *does* now — the behavioural counterpart to MAP's structure — folded from
closed work-items by `reconcile` at closeout, so current behaviour isn't something you reconstruct
by replaying the work-item chain. See [vs-sdd.md](vs-sdd.md#the-living-spec-problem-and-lcds-answer).

### 4. Earn the weight (anti-overengineering)

The lighter lane wins ties, and the heavy pipeline must be *earned* by real risk. This
discipline applies to LCD's own process and to the code it produces: make only the changes
the work requires; three similar lines beat a premature abstraction. "Don't manufacture a
Standard journal for a two-file change that finishes in one sitting" is a rule, not a
suggestion.

### 5. Risk-gated escalation

More small signals do **not** automatically mean more process. Two terms govern the heavy
lane:

- A **hard trigger** — architecture · parallel surfaces · EVAL · irreversibility
  (schema/migration/public API) — routes to Deep regardless of signal count.
- A **risk signal** — irreversibility OR multi-session cold-pickup — is the only thing that
  unlocks Deep from accumulation.

So 4+ signals route to Deep *only if a risk signal is among them*; pure soft-signal
accumulation (e.g. "6 small files, local refactor, one-commit revert, may span a session")
**caps at Standard**. Post-1M, "many small files" is a coordination cost, not a reason for
the full pipeline. File count is a soft proxy, never a hard trigger.

### 6. Multi-agent context discipline

When work fans out, the orchestrator **never reads bulk content into its own window** — it
dispatches a subagent, takes a ≤15-line digest, and writes that digest to a durable
artifact. Fan-out points: recon, deep-explore, per-surface implementation, review. Quick
lane uses zero subagents.

Deep-lane parallel surfaces run each implementer with `isolation: "worktree"` — each on its
own branch from the baseline commit, so a boundary violation is *structurally impossible*
(not detected after the fact); the orchestrator reconciles by merging the surface branches.
For a large multi-surface feature the opt-in `Workflow` tool drives the same fan-out
deterministically with schema-validated digests.

### 7. Structural coverage correctness

Lightness never comes at the cost of silently missing a path. Deep-lane work binds every
acceptance criterion to a surface (`AC-N (surfaces: …)`), and the audit gate
(`bin/audit-crosspath.sh`) checks that every `(AC × surface)` pair has a declared handler
that exists *and* a passing test carrying the literal `AC-N (SURFACE)` token — before a PR
can open. Paths that can be *silently wrong* (a scorer, ranker, recommender, or LLM output)
are pushed toward an `EVAL` criterion measured against a frozen golden dataset.

### 8. Self-contained and overridable

LCD **ships** the rules its lanes depend on — `testing`, `no-overengineering`,
`no-downgrade`, `refinement-protocol`, `versioning`, `commits`, and `ac-convention` — read
via `${CLAUDE_PLUGIN_ROOT}/rules/`. It works on any project without relying on your
machine's global config, and a project may override any rule with its own
`.claude/rules/<name>.md`. The Deep-lane plan's Constitution check reads them from there.

## Where to go next

- [vs-sdd.md](vs-sdd.md) — how LCD differs from spec-driven development tools.
- [../examples/quickstart.md](../examples/quickstart.md) — a worked walkthrough
  (onboard → Quick → Deep → resume).
- [../rules/lcd.md](../rules/lcd.md) — the full methodology reference.

## Sources

The pillars were argued from first principles; these are the primary sources they converged with:

- Anthropic, [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
  (2025) — the attention budget, context rot, just-in-time retrieval, compaction, structured
  note-taking (pillars 1, 3, 6).
- Anthropic, [Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
  (2025) — progressive disclosure (pillar 1 applied to LCD's own footprint).
- Martin Fowler, [martinfowler.com](https://martinfowler.com/) (2026-01) — relays Kent Beck's
  critique of specs frozen before implementation (pillars 2, 4, 5 and re-routing).
