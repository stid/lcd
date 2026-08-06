---
name: triage
description: Lean Context Development triage. Use when starting non-trivial new work in any LCD-onboarded project — a new feature, a multi-file change, a refactor that alters architecture, or anything you'd want a fresh session to pick up cold. Scores the work, picks a lane (Quick / Standard / Deep), states it in one line, and routes. Not for typo fixes, single-line edits, dependency bumps, formatting, or a bug fix whose cause is already known.
user-invocable: true
---

# LCD Triage (the front door)

The single entry point for new work under Lean Context Development: score the work, pick a lane,
route. Guiding principle — spend the minimum process the work needs, and write down exactly
enough that a cold session resumes cheaply.

## Step 0 — resolve project context (cheap)

Read `.claude/rules/lcd-conventions.md`'s `<!-- lcd-conventions:v1 -->` block for `artifact-root`
(default `docs/lcd`). If the project has no `lcd-conventions.md`, it isn't onboarded — say so and
suggest `/lcd:onboard` (then proceed in Quick lane for the immediate ask, since you have no MAP yet).
Glance at `<artifact-root>/MAP.md` Zones/Invariants only if the work is clearly Standard/Deep —
skip it for obviously-Quick work (don't pay for context you won't use).

If the block has `living-spec: on` and the work is Standard/Deep, also read **only the SPEC
section for the work's surface(s)** in `<artifact-root>/SPEC.md` (not the whole file — the same
selective discipline as resume reading DECISIONS headers). This is what the system already does in
that area, so you don't re-implement or contradict an existing capability. Skip for Quick work and
when `living-spec` is off.

## Step 1 — score the work (six signals)

Count how many signals fire toward the heavier columns:

| Signal | Quick | Standard | Deep |
|---|---|---|---|
| Files touched | 1–2 | 3–8 | 9+ |
| Architecture impact | none | local/contained | new module · cross-cutting · new dependency |
| Surfaces (CLI/HTTP/MCP/RENDER/DB/EVAL) | 0–1 | 1, or 2 sharing one path | 2+ parallel, or any EVAL |
| Reversibility | trivial revert | one-commit revert | schema/migration/public API |
| Cold-pickup plausibility | one sitting | may span a session | multi-session / multi-phase |
| Silently-wrong risk | none | low | scorer/ranker/LLM-output → EVAL |

**File count is a soft proxy** — post-1M it measures coordination/review cost, not "will it fit," so
it is **not** a hard Deep trigger. Resumability (cold-pickup) and the hard triggers carry the real
routing; the cap in Step 2 keeps pure file-count accumulation from reaching Deep.

## Step 2 — route

Two terms decide the heavy lane:

- A **hard trigger** is any Deep-column hit on **architecture / parallel-surfaces / EVAL /
  irreversibility** (schema/migration/public API).
- A **risk signal** is **irreversibility** (as above) **OR multi-session cold-pickup** — the signals
  whose downstream cost actually warrants the full pipeline.

Then:

- **Any hard trigger → Deep** (regardless of count).
- **Otherwise, count the signals firing toward heavier columns:**
  - **0–1 → Quick.**
  - **2–3 → Standard.**
  - **4+ → Standard, UNLESS a risk signal is among them → Deep.** Pure soft-signal accumulation
    (no hard trigger, no risk signal) **caps at Standard**.
- **Ties round DOWN** (anti-overengineering). The user may override in one word ("make it deep", "just do it").

## Step 3 — state the verdict in ONE line, then proceed

Format: `LCD → <Lane> (<n> signals): <artifact note>. <one-clause reason>.`
e.g. `LCD → Standard (3 signals): single JOURNAL at docs/lcd/work/export-csv/. 4 files, 1 surface, reversible, may span a session.`
Do not over-explain. One line, then act.

### Worked examples (the routing edges)

| Work | Signals firing | Hard trigger? | Risk signal? | Lane |
|---|---|---|---|---|
| Rename a config key across 6 files, local refactor, one-commit revert, may span a session | 4 (all Standard-level) | no | no | **Standard** |
| Same scope, but a deliberate multi-session migration effort | 4 | no | yes (multi-session) | **Deep** |
| Add CSV export — 4 files, 1 HTTP surface, reversible, one sitting | 2 | no | no | **Standard** |
| Add a relevance scorer (EVAL surface), 2 files | 1 | yes (EVAL) | — | **Deep** |
| New auth module with a schema migration | 2+ | yes (arch + irreversibility) | — | **Deep** |

## Step 4 — log the routing decision (telemetry)

One append per triage — this is how LCD measures itself instead of just asserting "most work is
Quick". After stating the verdict, append a single line to `<artifact-root>/triage-log.md` (create
it with a header if missing):

```bash
LOG="<artifact-root>/triage-log.md"
[ -f "$LOG" ] || printf '# LCD triage log\n\n<!-- date · work · n signals · lane · hard · risk -->\n\n' > "$LOG"
printf '%s · %s · %d signals · %s · hard:%s · risk:%s\n' "$(date +%F)" "<slug-or-3–5-word-desc>" <n> "<Lane>" "<yes|no>" "<yes|no>" >> "$LOG"
```

This single shared line is the **only** durable trace **Quick** lane leaves — it is *not* a
per-work-item artifact, so Quick's "no work-item folder" identity is unchanged. `/lcd:tidy`
summarizes the distribution. If the project isn't onboarded yet (no `lcd-conventions.md` /
artifact-root), skip the log — there's nowhere to put it.

### Closeout (outcome telemetry — the other half of the loop)

The triage line records which lane an item *got*; the **closeout** records whether the lane was
*right*. When a Standard/Deep work-item reaches its finish line (audit PASS, or the JOURNAL NOW
flips to done for surface-less work), append ONE more line to the same `triage-log.md`:

```
<date> · <slug> · closeout · <Lane> · audit: <PASS (first run) | PASS (run N) | n/a> · re-routes: <n> · red-green iters: <n> · interventions: <n>
```

- **audit** — result of the audit gate; `(first run)` vs `(run N)` records whether it passed
  first try. `n/a` when no surface was declared.
- **re-routes** — lane changes mid-flight (each also has its own fresh triage line).
- **red-green iters** — iterations the build loop used (it records this in the JOURNAL LOG).
- **interventions** — human/orchestrator corrections mid-run (boundary-hook denials, redirects,
  malformed-artifact rework).

**Quick lane gets no closeout** — there is no work-item to close; its triage line is its whole
trace (a Quick item that *escalated* leaves the escalation triage line, which is the signal).
The audit command appends the closeout on PASS; for surface-less Standard work, append it in the
same edit that marks the JOURNAL done. `/lcd:tidy` reads both line shapes and flags
miscalibrations — this is what turns the lane thresholds from designed constants into data-tuned
ones.

**Independent evaluation at closeout (when `closeout-evaluator: on`).** After the audit gate
passes and before the closeout line, dispatch the plugin's `lcd-evaluator` agent (read-only,
fresh context) with the slug, ACs, and baseline..HEAD diff. It attempts to refute the green
suite — degenerate passes, untested AC behaviour, suite-blind changes — and returns `file:line`
findings. Record the verdict in the JOURNAL LOG; findings are advisory but surface them before
any PR. Off by default: the same session that wrote the code judging it done is the failure mode
this key exists to remove.

**Compaction at closeout (when `living-spec: on`).** Right after the closeout line, invoke
`lcd:reconcile <slug>` to fold this work-item's ACs into `<artifact-root>/SPEC.md` — so the
living current-state index stays current and the next triage reads it instead of replaying the
work-item chain. The Deep `/lcd:audit` does this on PASS; for surface-less Standard work, run
it in the same edit that marks the JOURNAL done. When `living-spec` is off, skip it (reconcile is
a no-op anyway). **Enable nudge:** if `living-spec` is off but `triage-log.md` already shows ≥5
closed Standard/Deep items, mention once that the project may have outgrown the work-item chain and
could enable `living-spec` — a suggestion, not an action.

---

## Lane: Quick

No artifacts. No subagents. Implement directly, honoring the global TDD rules (test first where a
test makes sense). If a genuine decision gets made along the way, append one line to
`<artifact-root>/DECISIONS.md`. That's it — do not create a work-item folder.

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
single-session token use). Fan out only when the surfaces are genuinely independent (disjoint
boundaries) AND at least two are individually substantial. Surfaces that share most of one code
path, or a feature one sitting covers sequentially, stay in-session — the pipeline above is fully
Deep with zero subagents.

When fan-out is warranted: **commit a baseline first** (spec/plan/tasks + failing tests), then read
`${CLAUDE_PLUGIN_ROOT}/skills/triage/references/fanout.md` at that moment — it carries the
mechanics (default async worktree-isolated `lcd-implementer` dispatch, the opt-in `Workflow`
variant, the per-surface digest contract, the reconcile/merge procedure). Don't dispatch from
memory of it; it lives outside this skill precisely so the common no-fan-out triage never pays
for it.

Phase commands refuse if the prior artifact is missing — that gate is the point.

## Resuming and refining

- A context reset mid-work-item → `/lcd:resume <slug>` rebuilds from MAP + the JOURNAL
  resume block + DECISIONS headers in <~2k tokens.
- If you discover mid-flight that a STEP/task/MAP entry is wrong, invoke `lcd:refine` — it
  corrects the artifact and logs the change without waiting to be asked.

## Re-routing mid-flight (triage isn't one-shot)

Triage scores up front with imperfect information. If the lane proves wrong, **correct the lane** —
don't restart, and don't soldier on in the wrong one. `refine` fixes a wrong STEP/MAP entry *within*
a lane; re-routing fixes the lane itself.

- **Escalate** when the work outgrows its lane:
  - **Quick → Standard:** open `work/<slug>/JOURNAL.md` and backfill STEPS + EDIT BOUNDARY from what
    you've already done — carry the work forward, don't lose it.
  - **Standard → Deep:** seed `spec.md` / `plan.md` / `tasks.md` from the JOURNAL; keep the JOURNAL as
    the resume anchor above the pipeline, don't discard it.
- **De-escalate** when the work proved smaller than scored (**Deep → Standard**, **Standard → Quick**):
  collapse to the lighter artifact. The lighter lane wins ties, so de-escalation is *encouraged*, not
  grudging.
- **Either way, record the reason** — one line in the JOURNAL NOW/LOG and a `D-NNN` in `DECISIONS.md`
  (e.g. "re-routed Standard→Deep: the migration turned out irreversible"). The *why* is what a cold
  session needs. Append a fresh `triage-log.md` line (Step 4) for the new lane so the log reflects
  where the work actually ran.

## Keep it light (the whole point)

Most work is Quick. The lanes exist so the *rare* large feature is organized and resumable — not so
every task carries ceremony. When in doubt, the lower lane.
