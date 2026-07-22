---
name: reconcile
description: Fold a closed LCD work-item's acceptance criteria into the project's living current-state spec (SPEC.md) at closeout. Runs only when `living-spec: on` in lcd-conventions. Use at a work-item's finish line — after audit PASS (Deep) or when the JOURNAL flips to done (Standard) — to compact the frozen delta into the one document that says "what the system does now". Not for mid-work edits (that's lcd:refine).
user-invocable: true
allowed-tools: [Read, Edit, Write, Bash, Grep]
---

# LCD Reconcile (the compaction step)

The one-directional fold **delta → living spec** at closeout. A work-item `spec.md` (or a
Standard JOURNAL's inline ACs) is the *frozen delta* — what one change added. `SPEC.md` is the
*living current-state index* — what the system does now. Reconcile compacts the former into the
latter so the next person scoping work reads one lean document instead of replaying every closed
work-item. The append-only logs (`DECISIONS.md`, `triage-log.md`) are never rewritten by this — it
only *adds* a supersede entry when a capability is replaced.

Distinct from `lcd:refine`: refine fires autonomously mid-work for small drift corrections
*within* a work-item and explicitly avoids bulk rewrites. Reconcile fires once, at a defined
lifecycle gate, and processes a completed delta. Different trigger, scope, and size.

## Step 0 — gate on the flag (no-op when off)

Read `.claude/rules/lcd-conventions.md`'s `<!-- lcd-conventions:v1 -->` block. If `living-spec`
is not `on`, or there is no `spec:` key, **do nothing and say so** ("living-spec is off — skipping
compaction"). This is the common case; most projects never turn it on, and Quick-lane work never
reaches here. Resolve `artifact-root` and the `spec:` path (default `<artifact-root>/SPEC.md`).
If `SPEC.md` doesn't exist yet, create it from `${CLAUDE_PLUGIN_ROOT}/templates/living-spec.md`
(fill `<PROJECT_NAME>`), then continue.

## Step 1 — extract the delta's capabilities

Pick the source for slug `<slug>`:
- **Deep lane:** `<artifact-root>/work/<slug>/spec.md`.
- **Standard lane:** the work-item `JOURNAL.md` (its inline ACs use the identical
  `**AC-N** (surfaces: <CSV>): <body>` format, so the same parser reads it).

Run `parse-acs.sh <source>` (ships in the plugin `bin/`, on PATH). Three outcomes:
- **Rows returned** → each `<id>\t<surfaces>\t<body>` row is a capability to fold.
- **Non-zero with "no AC declarations found"** → the surface-less Standard case (a JOURNAL with no
  inline ACs). Fall back to **one** capability: surface `none`, body = the JOURNAL `Goal` line,
  no AC id. Do not treat this as an error.
- **Non-zero with a "malformed AC" / "invalid surface token" message** → a real defect in the
  delta. Stop and report it; don't fold a malformed spec.

## Step 2 — fold each capability into SPEC.md (new vs replace)

For each capability, read the matching surface section of `SPEC.md` and judge — this is the
judgement that makes reconcile a skill, not a script:

- **NEW capability** (the system couldn't do this before): add one terse row under its surface
  section — `| <one-line current behaviour> | <AC ids> | D-NNN (<slug>) |`. Keep it to a single
  line; if it wants a paragraph, the detail stays in the delta / the D-NNN, not here.
- **REPLACES an existing capability** (this change altered behaviour already indexed): **rewrite
  that row in place** to the new behaviour, and **append a supersede entry to `DECISIONS.md`**
  (`## D-NNN · <date> · <capability> now <new behaviour>` with `Status: active`, and mark the
  prior decision `superseded by D-NNN`). `SPEC.md` stays current-only — never keep a graveyard of
  old rows there; the history lives in the append-only `DECISIONS.md`.

**Stale markers.** A `· stale: <date>` suffix on a row's Provenance means Quick-lane work changed
that behaviour after the last fold (a marker, not a fold — the Quick lane's one allowed SPEC
touch). When your fold covers that capability, the rewrite **clears the marker** (verify the new
row text reflects the Quick change too, not just this work-item's delta). Leave markers on rows
this fold doesn't touch.

**Decay of backfill rows into rigor.** A row whose provenance reads `D-NNN (backfill)` was
seeded by onboard from code, not from audited ACs (a lower-confidence tier). When the work-item
you're folding touches that capability, treat it as a **REPLACES**: rewrite the row with the now
AC-pinned behaviour and set provenance to the work-item's real `D-NNN` (dropping the `(backfill)`
marker) — this is how the provisional seed becomes verified over time. Don't leave a backfilled row
in place when you have an AC-pinned truth for it.

Group rows under the correct surface heading (`CLI | HTTP | MCP | RENDER | DB | EVAL | none`).
A multi-surface AC gets one row per surface section, or a single row whose ACs column lists them —
prefer one row per section so each section reads as a standalone index.

## Step 3 — provenance, stamp, log

- **Provenance** points at the durable `D-NNN`, with the slug in parens as a breadcrumb (it may
  dangle after `/lcd:tidy` prunes the work-item — that's expected). If the work-item never
  earned a project-wide `D-NNN`, create one now recording the capability ("D-NNN · <date> ·
  <slug> shipped: <one line>", scope project-wide) so SPEC has a stable anchor to cite.
- **Stamp** `Last compacted: <date>` at the top of `SPEC.md`.
- **Log** one line in the work-item `JOURNAL.md` LOG: `<date> — reconciled: folded AC-1..N →
  SPEC.md/<surface>`. No new telemetry shape — the closeout line in `triage-log.md` already
  records the finish.

## The protocol (bounded by refinement-protocol)

Per the global `refinement-protocol` rule, even though closeout invoked you:
1. **Restate** the fold: "folding stats-surfaces: AC-1 (CLI) + AC-2 (HTTP) → 2 new SPEC rows".
2. **List what stays unchanged** — the SPEC sections / DECISIONS entries you are NOT touching.
3. **Make the edits**, then log.

## Autonomy boundary — when to STOP and ask

- A capability's behaviour **contradicts** an existing SPEC row in a way that isn't a clean
  supersede (two work-items disagree on current behaviour) → surface it; don't pick a winner
  silently.
- The fold would need to **delete** a capability (a feature was removed). Confirm the removal is
  intended, then rewrite/remove the row and record a superseding D-NNN — never drop behaviour from
  the index without a recorded why.

## Keep it light

Reconcile is a few SPEC rows + at most one supersede entry + a log line. If folding one work-item
rewrites half of SPEC.md, the delta wasn't really one change — say so rather than forcing it.
