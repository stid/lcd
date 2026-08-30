# Re-routing mid-flight (triage isn't one-shot)

> Loaded on demand from `lcd:triage` when the lane itself proved wrong — outside the SKILL so
> the common correctly-routed path never pays for it. `refine` fixes a wrong STEP/MAP entry
> *within* a lane; re-routing fixes the lane.

Triage scores up front with imperfect information. If the lane proves wrong, **correct the
lane** — don't restart, and don't soldier on in the wrong one.

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
  session needs. Append a fresh `triage-log.md` line (triage Step 4) for the new lane so the log
  reflects where the work actually ran.
