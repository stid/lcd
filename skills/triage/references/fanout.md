# Deep-lane fan-out mechanics (read at the moment you fan out)

> Loaded on demand from `lcd:triage` — the routing rule (when a fan-out is worth its token
> multiple) lives in SKILL.md; this file is the *how*. Precondition: a committed baseline
> (spec/plan/tasks + failing tests) and disjoint per-surface EDIT BOUNDARY rows.

Two ways to run the fan-out — both make the boundary *structural*, not merely instructed:

## Default — async worktree-isolated implementers

Dispatch the plugin's **`lcd-implementer`** agent per surface with `isolation: "worktree"` **and
`run_in_background: true`** — each runs in its own git worktree on its own branch from the baseline
commit, so an out-of-boundary edit is impossible, not caught after the fact. The boundary rules and
digest contract are baked into the agent definition; the dispatch prompt only supplies slug,
surface, boundary paths, and the `AC-N (SURFACE)` list. Each implementer:

1. Commits its boundary-scoped work on its worktree branch, makes only **its** `AC-N (SURFACE)`
   test(s) pass, reuses shared primitives (never reimplements core logic a `none`-surface AC owns).
2. Returns a **change-manifest digest** (schema below); the dispatch hands back its `worktreeBranch`.

**Don't block on the fan-out.** While implementers run, the orchestrator keeps working: prep the
reconciliation (merge order, the full-suite command, the `lcd-reviewer` dispatch with the manifest
slots ready) and check in on digests as they land. If a digest reports an out-of-boundary need or
drift from its ACs, intervene on **that** implementer (message it the correction, or fix the scoping
and re-dispatch) while the others keep running — the slowest surface shouldn't bottleneck the rest,
and a long-lived implementer keeps its surface context across follow-ups (cheaper than respawning).

> **/loop recipe (optional — harness feature, never depend on it).** Completion notifications
> only fire when an implementer *finishes*; mid-flight drift is what they miss. If the harness
> offers `/loop`, a generous-interval monitor fills that gap: `/loop 5m check the implementer
> digests; intervene only if one is off-track or blocked; otherwise say nothing`. Prefer
> event-driven signals (background-agent notifications, the Stop hook) — a polling loop is
> otherwise the most anti-LCD construct there is; `/loop` only fills the gaps between events.

## Reconcile (when all digests are in)

The orchestrator merges each surface branch onto the baseline — disjoint boundaries merge clean; a
merge conflict means two surfaces claimed the same file (a scoping error — fix the boundaries,
don't paper over it). Run the **full** suite (the integration check the parallel agents can't do
alone), fan out the **`lcd-reviewer`** agent with the change manifests for cross-surface
consistency (same input → same result), then `/lcd:audit <slug>` as the gate.

## Recommended for a large multi-surface feature — the `Workflow` tool

When the user opts in (they include "workflow", or you offer it), express the whole fan-out as a
deterministic workflow: `parallel` per-surface implementers, each `isolation: 'worktree'` with a
**schema-validated** digest, then a review stage, then the full-suite + audit gate. Reference
script: `${CLAUDE_PLUGIN_ROOT}/templates/fanout.workflow.js` — it moves the reconcile/boundary
bookkeeping into harness-run JS and enforces the digest contract at the tool layer. Run the
workflow in the background too, so the orchestrator preps reconciliation while it executes.
`Workflow` is **opt-in**; if the user hasn't asked for it, use the default path above.

## Per-surface implementer digest (shared contract)

Both paths return the same shape per surface — prose-contracted on the Agent path, schema-validated
on the Workflow path:

- `surface` — the surface token (CLI/HTTP/MCP/RENDER/DB/EVAL)
- `filesChanged` — paths touched (must all be within this surface's EDIT BOUNDARY)
- `acsCovered` — the `AC-N (SURFACE)` test(s) now passing
- `notes` — ≤6 bullets: what was done, primitives reused, anything reconcile/review must know
- `worktreeBranch` — the branch to merge (worktree path; from `git rev-parse --abbrev-ref HEAD`)
