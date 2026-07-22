# LCD vs. spec-driven development

LCD grew out of spec-driven development (SDD) and keeps its rigor — but reorganizes *when*
that rigor applies. This page explains the difference. For the idea and pillars behind LCD,
see [why-lcd.md](why-lcd.md).

## What SDD is

Spec-driven development puts a written specification at the center of AI-assisted coding.
The canonical implementation is GitHub's [Spec Kit](https://github.com/github/spec-kit),
whose core flow is:

```
constitution → specify → plan → tasks → implement
```

with optional quality gates (`clarify`, `checklist`, `analyze`) layered in for bigger work.
Each phase produces a Markdown artifact that feeds the next, so the agent works from
structured context instead of ad-hoc prompts. It's a genuinely good idea: a spec the agent
can't drift from, a plan that respects your architecture, and a task breakdown ordered by
dependency.

**Where SDD shines:** risky, multi-surface, multi-session features — exactly the work that
benefits from an explicit spec, an architecture plan, and a coverage check.

**Where it strains:** as an *always-on default*. Running `specify → plan → tasks` for a
one-file bug fix is overhead with no payoff, and it trains everyone to either skip the
process (losing its benefit when it matters) or pay ceremony tax on trivial work. Kent Beck's
critique (relayed by Martin Fowler, 2026-01) names the deeper flaw: a spec frozen before
implementation "encodes the bizarre assumption that you aren't going to learn anything during
implementation." LCD's mid-flight re-routing exists for exactly that learning — the lane, and
the spec, stay correctable.

## LCD's relationship to SDD

LCD doesn't replace the SDD pipeline — it **demotes it to one lane you earn.** LCD's *Deep*
lane *is* essentially a full SDD run (`spec → plan → tasks → test-gen → red-green → audit`,
with a Constitution check borrowed from the same lineage). The difference is everything
*around* that lane:

- A **Quick** lane with zero artifacts for the common case.
- A **Standard** lane with a single resumable journal — the middle ground SDD's one-size
  pipeline doesn't have.
- A **triage front door** that picks the lane by scoring the work, so the human doesn't
  have to decide "is this big enough for the full process?" each time.
- A **durable spine** (`MAP`, `DECISIONS`, `JOURNAL`) engineered for cheap cross-session
  resume — because LCD treats context, not just the spec, as the scarce resource.

In short: SDD asks *"how do we make the agent follow a spec?"* LCD asks *"how much process
does this particular work need, and how do we resume it cheaply when the context is gone?"*
— and keeps the full SDD pipeline as the answer for the cases that warrant it.

## The living-spec problem (and LCD's answer)

SDD's hardest open question is what happens to a spec *after* implementation. In Spec Kit the
default is a new numbered `specs/NNN-feature/spec.md` per change, frozen once planning ends — so
the truth about "what does this system do now" is spread across the whole chain of frozen specs,
and you reconstruct it by replaying them. The community has debated this at length without a
settled answer (see Spec Kit discussions
[#152](https://github.com/github/spec-kit/discussions/152),
[#1804](https://github.com/github/spec-kit/discussions/1804),
[#916](https://github.com/github/spec-kit/issues/916)) — the recurring proposal is some form of
*target-state + delta with periodic compaction*: keep the per-change specs as deltas, maintain one
living current-state spec, and fold closed deltas into it. The ecosystem has since confirmed the
problem is real: Spec Kit grew a spec-adherence retrospective extension and the community built
standalone reconcile tooling for drift — bolted on after the fact. LCD builds the fold in at
closeout, and Quick-lane changes that touch an indexed capability leave a `stale:` marker on the
row, so the index flags its own lag instead of silently lying (a stale spec is worse than no spec).

LCD adopts that, scoped to its context-economy ethos. It separates three tiers of truth:

- **the frozen delta** — `work/<slug>/spec.md` (or a Standard JOURNAL's inline ACs): what one
  change added; freezes at `implemented`.
- **append-only history** — `DECISIONS.md`: *why* a capability exists or changed; never rewritten.
- **the living current-state index** — `SPEC.md`: what the system does *now*; current-only (a
  replaced capability is rewritten in place, its history kept in DECISIONS).

`lcd:reconcile` does the one-way fold (delta → `SPEC.md`) at closeout, so the index stays
current without a separate maintenance pass. It is **opt-in** (`living-spec: off` by default) and
deliberately *not* bidirectional and *not* a CI drift-gate — for a young project the work-item
chain is the current state and an index is overhead; turn it on once "what does this do now" is
expensive to re-derive. Note that `MAP.md` already gave LCD a living *structural* index (where
things live); `SPEC.md` is the *behavioural* counterpart (what the system does) — a different axis,
kept as a separate file.

## Side-by-side

| Dimension | Spec-driven (e.g. Spec Kit) | LCD |
|---|---|---|
| **Default weight** | The pipeline, for any non-trivial change | **Quick** lane — no artifacts — for the common case |
| **Lane choices** | One pipeline (optionally + quality gates) | Three lanes: Quick / Standard / Deep |
| **Who picks the weight** | The human, per task | `triage` scores six signals and routes |
| **Middle ground** | None — you're in the pipeline or improvising | **Standard**: one journal, granular steps, no spec/plan/tasks split |
| **Escalation trigger** | Author's judgment | Hard triggers + risk signals; soft-signal accumulation caps at Standard |
| **Resume after a reset** | Re-read the spec/plan/tasks artifacts | MAP + JOURNAL `lcd-resume:v1` block → ~2k tokens |
| **Orchestrator context** | Reads each artifact to proceed | Takes ≤15-line subagent digests; never bulk content |
| **Parallel surfaces** | Tasks marked parallelizable; you coordinate | `isolation: "worktree"` per surface — boundary violation structurally impossible |
| **Coverage gate** | Cross-artifact `analyze` / checklists | `audit`: every `(AC × surface)` needs an existing handler **and** a passing `AC-N (SURFACE)` test before a PR opens |
| **Current-state of the system** | Replay the chain of frozen per-feature specs | Optional living `SPEC.md` index, folded from closed deltas by `reconcile` at closeout (`MAP.md` covers structure) |
| **Distribution** | A CLI you `init` into a repo | A Claude Code plugin; bundles its own rules, overridable per project |

## When to reach for which

- **Use full SDD / the Deep lane** when the work is architectural, spans multiple parallel
  surfaces, is hard to reverse (schema, migration, public API), or can be *silently wrong*
  (a scorer or LLM output that needs an EVAL). LCD routes these to Deep automatically.
- **Use a lighter lane** — and let LCD pick it — for most changes: those that are a few
  files, reversible, and finishable in a sitting or two. That's where SDD's fixed pipeline
  costs more than it returns, and where LCD's Quick/Standard lanes keep you fast without
  losing resumability.

The two aren't rivals so much as different framings of the same goal. If you already love
spec-driven development, LCD is "SDD, but only when the work earns it — with a context
budget and a cheap resume built in."

## Sources

- [github/spec-kit](https://github.com/github/spec-kit) — the Spec Kit toolkit
- [Spec Kit documentation](https://github.github.com/spec-kit/)
- [Spec-driven development with AI — the GitHub Blog](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- Spec Kit on evolving specs — discussions [#152](https://github.com/github/spec-kit/discussions/152), [#1804](https://github.com/github/spec-kit/discussions/1804), issue [#916](https://github.com/github/spec-kit/issues/916)
- Martin Fowler, [martinfowler.com](https://martinfowler.com/) (2026-01) — relays Kent Beck's
  critique of specs frozen before implementation
