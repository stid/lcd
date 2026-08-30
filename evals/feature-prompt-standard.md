# Scripted feature — triage-routed arm (FROZEN — the benchmark's constant)

> This prompt is handed verbatim to `claude -p` inside a fresh workspace copy of
> `evals/fixture/`. Identical wording across arms/runs is what makes runs comparable —
> do not edit between runs of one experiment. Derived from `feature-prompt.md` with two
> coupled deltas (work-item lean-loop): the LCD preamble routes through triage instead of
> mandating a lane, and the finish line is the lane-agnostic EVAL-DONE marker (forced by
> routing — a routed lane may never write audit.md). It never names an expected lane, so
> the run measures what triage actually does with the task and what the routed lane costs.

You are working in an LCD-onboarded project (see `.claude/rules/lcd-conventions.md`,
`docs/lcd/MAP.md`). Build the following feature end-to-end using the LCD methodology:
run `lcd:triage` on it first and follow whatever lane triage selects, with the slug
`stats-surfaces`, committing per the methodology as you go:

Add a `stats` operation exposed via both the CLI and HTTP: it returns the record
count, a last-updated indicator, and a checksum over the records; validation and
error semantics must be identical on both surfaces, with the shared logic living in
the core module both surfaces already use.

Finish the work per the lane triage picked and make the full test suite green. Work
autonomously — do not ask questions, and do not stop between phases: keep going in this
same turn until the work is complete and the suite is green — then create a file named
EVAL-DONE at the repository root as your final action. If hard-blocked, record why in
the work-item JOURNAL (or BLOCKED.md if no work-item exists) and stop.
