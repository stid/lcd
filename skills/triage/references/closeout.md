# Closeout contract (read at a work-item's finish line)

> Loaded on demand from `lcd:triage` / `/lcd:audit` — it lives outside the triage SKILL so the
> common triage-time path never pays for it (the same discipline as `fanout.md`). Applies when a
> **Standard/Deep** work-item reaches its finish line: audit PASS, or the JOURNAL NOW flips to
> done for surface-less Standard work. **Quick lane gets no closeout** — there is no work-item to
> close; its triage line is its whole trace (a Quick item that *escalated* leaves the escalation
> triage line, which is the signal).

Run the steps in this order — the evaluator verdict lands before the closeout is logged; the
fold comes after.

## 1 — Independent evaluation (only when `closeout-evaluator: on`)

After the audit gate passes and before the closeout line, dispatch the plugin's `lcd-evaluator`
agent (read-only, fresh context) with the slug, the artifact root, the ACs, and the
baseline..HEAD diff range. It attempts to refute the green suite — degenerate passes, untested
AC behaviour, suite-blind changes — and returns `file:line` findings. Record the verdict in the
JOURNAL LOG (`evaluator: stands`, or `evaluator: challenged (<n> findings)` plus the findings
verbatim) and present the findings to the user **before** suggesting any PR. The verdict is
advisory — it doesn't reopen the audit result — but on `challenged` the sane order is fix,
re-audit, and only then close out. Skip when the key is `off` or absent; the same session that
wrote the code judging it done is the failure mode this key exists to remove.

## 2 — The closeout line (always)

Append ONE line to `<artifact-root>/triage-log.md` via the plugin's writer script (ships in
`bin/`, on PATH; it validates the shape and creates the log with its header if missing):

```bash
lcd-triage-log.sh closeout --root <artifact-root> --slug <slug> --lane <Standard|Deep> \
  --audit "<result>" --reroutes <n> --iters <n> --interventions <n>
```

- **`--audit`** — `PASS (first run)` · `PASS (run N)` (N = audit runs this slug needed to reach
  PASS) · `PASS (test-presence)` (the Standard-lane audit) · `n/a` or `n/a (<note>)` (no surface
  declared).
- **`--reroutes`** — lane changes mid-flight (each also has its own fresh triage line).
- **`--iters`** — iterations the red-green loop recorded in the JOURNAL LOG; `n/a (<note>)`
  where the loop never ran (e.g. docs-only work).
- **`--interventions`** — human/orchestrator corrections mid-run (boundary-hook denials,
  redirects, malformed-artifact rework); a parenthesised note is allowed.

Pull lane / re-routes / iterations / interventions from the JOURNAL (NOW.Lane and the LOG). The
triage line recorded which lane the item *got*; this line records whether the lane was *right* —
`/lcd:tidy` reads the two shapes against each other and flags miscalibrations, which is what
turns the lane thresholds from designed constants into data-tuned ones. The Deep `/lcd:audit`
appends this on PASS; for surface-less Standard work, append it in the same edit that marks the
JOURNAL done.

## 3 — Compaction (only when `living-spec: on`)

Right after the closeout line, invoke `lcd:reconcile <slug>` to fold this work-item's ACs into
`<artifact-root>/SPEC.md`, so the living current-state index stays current and the next triage
reads it instead of replaying the work-item chain. Skip when the flag is off (reconcile is a
no-op anyway).

**Enable nudge:** if `living-spec` is off but `triage-log.md` already shows ≥5 closed
Standard/Deep items, mention once that the project may have outgrown the work-item chain and
could enable `living-spec` — a suggestion, not an action.
