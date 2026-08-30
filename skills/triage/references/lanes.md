# Lane execution contracts (read for the lane the verdict picked)

> Loaded on demand from `lcd:triage` after Step 3's verdict — the lane bodies live outside the
> triage SKILL so scoring never pays for the lanes not taken (the same discipline as
> `closeout.md` / `fanout.md`). Read the section for the routed lane; skip the rest.

## Lane: Quick

No artifacts. No subagents. Implement directly, honoring the global TDD rules (test first where a
test makes sense). If a genuine decision gets made along the way, record it as a `D-NNN` block in
`<artifact-root>/DECISIONS.md` (the template's format — a one-line free-form append breaks the
`D-NNN` referencing SPEC provenance depends on). That's it — do not create a work-item folder.

**Staleness marker (only when `living-spec: on`):** if the change alters behaviour already indexed
in `SPEC.md`, append `· stale: <date>` to that row's Provenance cell — a one-cell marker, **not** a
fold (no behaviour rewrite, no AC claim; folding stays Standard/Deep-only). The marker tells the
next reader "this row may lag reality"; the next `reconcile` that folds the capability clears it.
Skip when the change doesn't touch an indexed capability — most Quick work doesn't.

## Lane: Standard

One file carries the work: `<artifact-root>/work/<slug>/JOURNAL.md` (copy the JOURNAL template from
`${CLAUDE_PLUGIN_ROOT}/templates/JOURNAL.md`). Then:

1. **recon** (`lcd:recon`) if the work involves a library/API/pattern whose current best
   practice you're not certain of — run it in a subagent, write findings into the JOURNAL LOG and
   any durable choice into DECISIONS.md. Skip if the work is plainly within known territory.
2. **Fill the JOURNAL:** Goal, granular STEPS (tests-first ordering), EDIT BOUNDARY (the files you
   expect to touch), and — only if a surface needs the audit — inline ACs in the AC-N format.
3. **Build TDD:** for each STEP, write the failing test, make it pass minimally, keep STEPS +
   NOW.Next-action current as you go (so a reset resumes cleanly). Commit per meaningful step.
4. **verify:** if the change has a UI/RENDER surface, drive the app through the `claude-in-chrome`
   MCP tools (or the host project's own run/verify tooling, if it has any) to confirm it actually
   behaves; otherwise the test suite is the verification.
5. **audit (only if a surface was declared):** run `/lcd:audit <slug>` before a PR. For
   Standard it performs the **test-presence check** (each inline `AC-N (SURFACE)` has a passing
   test carrying that literal token); the full cross-path script needs Deep's spec+plan.
6. Keep the JOURNAL's NOW.Next-action accurate at the end (e.g. "open PR" or "done").

## Lane: Deep

Run the absorbed pipeline; each phase command resolves the artifact root and updates the JOURNAL:

```
recon (lcd:recon, subagent)   →  current best practice feeds the plan
/lcd:specify <slug> "<feature>" →  spec.md (+ seeds JOURNAL)
/lcd:plan <slug>                →  plan.md (architecture, Constitution, cross-path matrix)
/lcd:tasks <slug>               →  tasks.md (TDD-ordered; mirrored into JOURNAL STEPS)
/lcd:test-gen <slug>            →  failing tests (one per AC × surface)
lcd:redgreen-loop (skill)       →  per-fix commits until green
/lcd:audit <slug>               →  PR-creation gate
```

RENDER surfaces additionally get a live check via the `claude-in-chrome` MCP before audit.

For **parallel independent surfaces**, you MAY fan out one implementer subagent per surface, each
scoped to its EDIT BOUNDARY rows (the orchestrator holds only the per-surface digests, never the
bulk diffs). **Fan-out must earn its token multiple:** a subagent-per-surface run costs several
times a single-session build (Anthropic's own multi-agent measurements put such flows at many times
single-session token use). The gate is **test-independence**: fan out only when the committed
baseline's failing tests already partition the work — each surface's `AC-N (SURFACE)` tests can be
made to pass without touching another surface's boundary — AND at least two surfaces are
individually substantial. (This is the condition under which parallel implementers demonstrably
work; when the work collapses into one shared problem, parallel agents re-solve each other's task.)
Surfaces that share most of one code path, or a feature one sitting covers sequentially, stay
in-session — the pipeline above is fully Deep with zero subagents.

When fan-out is warranted: **commit a baseline first** (spec/plan/tasks + failing tests), then read
`${CLAUDE_PLUGIN_ROOT}/skills/triage/references/fanout.md` at that moment — it carries the
mechanics (default async worktree-isolated `lcd-implementer` dispatch, the opt-in `Workflow`
variant, the per-surface digest contract, the reconcile/merge procedure). Don't dispatch from
memory of it; it lives outside this skill precisely so the common no-fan-out triage never pays
for it.

Phase commands refuse if the prior artifact is missing — that gate is the point.
