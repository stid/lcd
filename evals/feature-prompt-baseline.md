# Scripted feature — baseline arm (FROZEN — the benchmark's constant)

> This prompt is handed verbatim to `claude -p` inside a fresh bare-project workspace
> derived from `evals/fixture/` with the methodology onboarding stripped. Its feature
> paragraph is byte-identical to `feature-prompt.md`'s (enforced by
> `tests/test-eval-baseline.sh`); only the process wrapper differs — that difference IS
> the experiment. Identical wording across runs of one experiment — do not edit between
> runs.

You are working in a small Node.js project. Build the following feature end-to-end,
writing tests for everything you add and committing as you go:

Add a `stats` operation exposed via both the CLI and HTTP: it returns the record
count, a last-updated indicator, and a checksum over the records; validation and
error semantics must be identical on both surfaces, with the shared logic living in
the core module both surfaces already use.

Finish with the full test suite green. Work autonomously — do not ask questions, and do
not stop between steps: keep going in this same turn until the feature is complete and
the suite is green. When, and only when, that holds, create a file named `EVAL-DONE` at
the repository root as your final action. If hard-blocked, record why in `BLOCKED.md` at
the repository root and stop.
