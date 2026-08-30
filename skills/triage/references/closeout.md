# Closeout contract (one action at a work-item's finish line)

> Loaded on demand from `lcd:triage` / `/lcd:audit` — it lives outside the triage SKILL so the
> common triage-time path never pays for it. Applies when a **Standard/Deep** work-item reaches
> its finish line: audit PASS, or the JOURNAL NOW flips to done for surface-less Standard work.
> **Quick lane gets no closeout** — its triage line is its whole trace (a Quick item that
> *escalated* leaves the escalation triage line, which is the signal).

Closeout is **ONE action**: append the closeout line via the plugin's writer script (ships in
`bin/`, on PATH; it validates the shape) — with the opt-in evaluator folded in immediately
before the append, and the opt-in spec fold immediately after, as parts of the same action:

```bash
lcd-triage-log.sh closeout --root <artifact-root> --slug <slug> --lane <Standard|Deep> \
  --audit "<result>" --reroutes <n> --interventions <n>   # --iters <n> optional
```

- **Before appending — only when `closeout-evaluator: on`:** dispatch the plugin's
  `lcd-evaluator` agent (read-only, fresh context) with the slug, artifact root, ACs, and the
  baseline..HEAD diff range; it attempts to refute the green suite. Record the verdict in the
  JOURNAL LOG (`evaluator: stands` / `evaluator: challenged (<n> findings)` + findings
  verbatim) and present findings **before** suggesting any PR. Advisory — but on `challenged`
  the sane order is fix, re-audit, then close out. The same session that wrote the code judging
  it done is the failure mode this key removes.
- **The line's fields** (pull from the JOURNAL — NOW.Lane and the LOG):
  - `--audit` — `PASS (first run)` · `PASS (run N)` · `PASS (test-presence)` (the Standard-lane
    audit) · `n/a` / `n/a (<note>)` (no surface declared).
  - `--reroutes` — lane changes mid-flight (each also has its own fresh triage line).
  - `--interventions` — human/orchestrator corrections mid-run (boundary-hook denials,
    redirects, rework); `(note)` allowed. Mandatory — it is the miscalibration metric.
  - `--iters` — red-green iterations, **optional**: include when the LOG has the count, omit
    otherwise (old lines with the field stay valid; readers accept both shapes).
- **After appending — only when `living-spec: on`:** invoke `lcd:reconcile <slug>` to fold this
  work-item's ACs into `<artifact-root>/SPEC.md`. (If `living-spec` is off but the log already
  shows ≥5 closed Standard/Deep items, mention once that the project may have outgrown the
  work-item chain — a suggestion, not an action.)

The triage line recorded which lane the item *got*; this line records whether the lane was
*right* — `/lcd:tidy` cross-reads the two shapes and flags miscalibrations, which is what turns
the lane thresholds from designed constants into data-tuned ones. The Deep `/lcd:audit` appends
this on PASS; for surface-less Standard work, append it in the same edit that marks the JOURNAL
done.
