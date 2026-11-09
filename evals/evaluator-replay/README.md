# Evaluator replay dataset

A frozen set of closeouts for measuring a change to the `lcd-evaluator` agent prompt. Each case
is one D-028 (T1-5.1, 2026-09-04) evaluator dispatch, replayed against the same code and prompt.
Only the agent definition varies between arms. Introduced by stid/lcd#26 (harness D-034).

## Cases

| id | state the evaluator saw | D-028 verdict | known defects (label → oracle in `cases.json`) |
|---|---|---|---|
| standard-1 | `1ff2917` | stands | none |
| standard-2 | `71c26ac` | challenged | `lastUpdated-advance` |
| standard-3 | `fb4a9a8` | stands | `checksum-first-record` (missed by D-028) |
| deep-1 | `c7bbe61` | stands | none |
| deep-2 | `6132f8d` | challenged | `checksum-count-only`, `stats-empty-query-parity` |
| deep-3 | `bcb0142` | challenged | `checksum-first-record` (missed), `stats-empty-query-parity`, `timestamp-bracket` |
| no-test-command | `5af6d64` | — | none: standard-1 plus one commit declaring no test command (AC-4) |

- **State.** The last commit before the dispatch timestamp in the original transcript.
- **Truncation.** Each bundle carries only the case refs at those commits, so the later
  "evaluator finding" fix commits are absent. `tests/test-eval-replay.sh` asserts this.
- **Prompts.** Each dispatch prompt is copied verbatim from the D-028 parent transcript, with
  the workspace path replaced by `{ROOT}`. Four of the six already invite running the suite.
  That is held constant across arms.
- **Oracle check (2026-11-08).** `slice(1)` on the checksum input survives the suite (27/27) at
  standard-3 and deep-3, and is killed at the other four.

## Re-run

```bash
evals/replay-evaluator.sh run --old-ref main --new-ref <branch> --reps 3 --out <dir>
evals/replay-evaluator.sh summarize --out <dir>
```

The runner prints mechanical columns:
- tree unchanged
- suite runs
- `mktemp` copies
- fixed-path deletes
- tokens
- cost
- verdict

Recall and finding reproduction are graded by hand into `evals/quality/`.

## Provenance

The bundles and prompts were built once from the harness workspaces `sandboxes/evals/t151-*` and
their Claude Code transcripts. The build steps:
1. Clone each workspace.
2. Force the case refs to the commits above.
3. Run `git bundle create <id>.bundle <refs>`.
4. Copy the evaluator `Agent` dispatch prompt and template its path.

Authors in the history are `eval@local` and the owner's GitHub noreply identity. The dataset
contains no machine paths.
