# Scripted feature (FROZEN — the benchmark's constant)

> This prompt is handed verbatim to `claude -p` inside a fresh workspace copy of
> `evals/fixture/`. Identical wording across arms/runs is what makes runs comparable —
> do not edit between runs of one experiment. Wording from
> `docs/lcd/work/fable5-leverage/experiment-deprescription.md` §Method.

You are working in an LCD-onboarded project (see `.claude/rules/lcd-conventions.md`,
`docs/lcd/MAP.md`). Build the following feature end-to-end using the LCD methodology's
Deep lane with the slug `stats-surfaces`, running the full pipeline — specify, plan,
tasks, test-gen, red-green build, audit — and committing per the methodology as you go:

Add a `stats` operation exposed via both the CLI and HTTP: it returns the record
count, a last-updated indicator, and a checksum over the records; validation and
error semantics must be identical on both surfaces, with the shared logic living in
the core module both surfaces already use.

Finish with the audit for `stats-surfaces` and make the full test suite green. Work
autonomously — do not ask questions, and do not stop between phases: keep going in this
same turn until the audit has run with all rows OK and the suite is green. If hard-blocked,
record why in the work-item JOURNAL and stop.
