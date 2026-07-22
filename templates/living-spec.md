# SPEC — <PROJECT_NAME> (living current-state)

> **What this system DOES now — a capability index, not documentation.** One line per
> capability; the detail lives in the cited `D-NNN` (history) and, until pruned, the work-item
> delta. **Current-state only**: a replaced capability is rewritten in place — its history is
> kept in `DECISIONS.md`, never here. Folded at closeout by `lcd:reconcile`. Read only the
> section for the surface/area you're about to touch, not the whole file. Opt-in: this file
> exists only when `living-spec: on` in `.claude/rules/lcd-conventions.md`.

**Last compacted:** <YYYY-MM-DD>

---

## Capabilities by surface

> One row per current capability. **Capability** = one terse line of what the system does now
> (behaviour, not implementation). **ACs** = the acceptance-criteria IDs that pin it. **Provenance**
> = the durable `D-NNN` that records the why (the work-item slug in parens is a breadcrumb — it may
> dangle after `/lcd:tidy` prunes the work-item, and that's fine). A `· stale: <date>` suffix
> on Provenance means Quick-lane work changed this behaviour after the last fold — treat the row as
> approximate until the next `reconcile` clears it. Delete any surface section that has no
> capabilities.
>
> **Backfill tier.** When `living-spec` is enabled on an *existing* project, onboard seeds the
> initial rows from MAP + code at capability-*group* altitude (clusters, not per tool/endpoint).
> Those rows are **code-derived, not AC-verified** — cite them as `D-NNN (backfill)` and add the
> banner below. They **decay into rigor**: `reconcile` supersedes each with a real AC-pinned `D-NNN`
> the next time a work-item touches that capability.

<!-- Backfill banner — keep only while backfilled rows remain; delete once all have decayed:
> ⚠️ Rows marked `D-NNN (backfill)` were derived from code on <date>, not AC-verified. Provisional
> seed; each decays into an AC-pinned row as work touches it. See D-NNN.
-->


### CLI

| Capability (current behaviour, one line) | ACs | Provenance |
|---|---|---|
| <e.g. `doctor` validates the conventions block and exits non-zero on FAIL> | AC-6 | D-014 (init-doctor) |

### HTTP

| Capability (current behaviour, one line) | ACs | Provenance |
|---|---|---|
| <…> | <…> | <…> |

### MCP

| Capability (current behaviour, one line) | ACs | Provenance |
|---|---|---|
| <…> | <…> | <…> |

### RENDER

| Capability (current behaviour, one line) | ACs | Provenance |
|---|---|---|
| <…> | <…> | <…> |

### DB

| Capability (current behaviour, one line) | ACs | Provenance |
|---|---|---|
| <…> | <…> | <…> |

### EVAL

| Capability (current behaviour, one line) | ACs | Provenance |
|---|---|---|
| <…> | <…> | <…> |

### Internal (surface: none)

> Invariants, calculations, and behaviours with no external surface — including the one-line
> capability `lcd:reconcile` folds from a surface-less work-item's `Goal`.

| Capability (current behaviour, one line) | ACs | Provenance |
|---|---|---|
| <…> | <…> | <…> |

<!--
What this file is FOR (and what it is NOT):
  - FOR: the single place to learn "what does this system do now" when scoping new work, so you
    don't replay the chain of closed work-items. Read the relevant surface section before
    planning a change to that surface.
  - NOT a changelog (that's the append-only DECISIONS.md), NOT documentation (no prose, no
    examples), NOT a structural map (that's MAP.md — where things live).
Leanness rules:
  - One line per capability. If a capability needs a paragraph, the detail belongs in its D-NNN.
  - Rewrite a superseded capability in place; never keep a graveyard of old behaviour here.
  - Surface sections use the fixed vocabulary {CLI, HTTP, MCP, RENDER, DB, EVAL, none}; delete
    any section with no rows.
This file is NOT read on cold start (resume reads MAP + JOURNAL block + DECISIONS headers) — it
is on-demand, consulted when planning new work.
-->
