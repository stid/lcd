# Evaluator replay: scoring (2026-11-08, stid/lcd#26, harness D-034)

The replay set is `evals/evaluator-replay/` (6 D-028 closeouts plus `no-test-command`). Each
case was run under two prompts:

| arm | ref | prompt |
|---|---|---|
| old | `main` df9da11 | the published 0.21.1 agent prompt |
| new | `feat/evaluator-exec` 543ccfb | the "Demonstrate, don't argue" section |

- **Runs:** 3 reps for each case and prompt. The no-test-command case ran under the new prompt
  only.
- **Environment:** `claude-fable-5-1`, CLI 2.1.319, settings-only isolation. Raw output is in the
  harness, `sandboxes/evals/replay-2026-11-08/` (39 rows, 0 `error` rows).
- **Graders:** one fresh agent per case. Each reproduced every finding in a throwaway clone: it
  re-ran every mutant and probe and wrote and ran gap-level kill tests.

## Mechanical (from `rows.tsv`)

| measure | old (18) | new, D-028 cases (18) | new, no-test-command (3) |
|---|---|---|---|
| tree unchanged | 18/18 | 18/18 | 3/3 |
| fixed-path `rm -r` | 1 | 0 | 0 |
| mean tokens | 130,769 | 183,146 (**1.40×**) | 138,649 |
| mean cost | $1.12 | ~$1.41 | ~$1.02 |
| verdict `challenged` | 8/18 | **18/18** | 3/3 |

`suite_runs` undercounts runs that use `--test-reporter`. `.commands.txt` truncates long output,
so AC-5 was graded against the `.jsonl`.

## Precision (new arm, every finding reproduced or refuted by a grader)

| case | reproduced | not-a-defect (true) | replay-artifact | reasoning | not reproduced |
|---|---|---|---|---|---|
| standard-1 | 7 | 0 | 0 | 0 | 0 |
| standard-2 | 5 | 0 | 0 | 0 | 0 |
| standard-3 | 7 | 1 | 0 | 0 | 0 |
| deep-1 | 3 | 5 | 0 | 0 | 0 |
| deep-2 | 9 | 4 | 0 | 0 | 0 |
| deep-3 | 11 | 2 | 3 | 1 | 0 |

- **No new-arm finding failed to reproduce.**
- **Replay artifact.** `audit.md` was untracked when D-028 dispatched, so the truncated bundle
  cannot hold it. Both arms flag it, and it is excluded.
- **D-028 "stands" closeouts.** The new arm's challenges there are real suite gaps; the shipped
  code is correct in every probe:
  - **standard-1 (3/3 challenged):** four distinct gaps.
  - **deep-1 (2/3 challenged):** first-add-only `lastUpdated`, and a per-process checksum salt.
    The old arm saw both and rated them advisory.

## Recall

| label (case) | old | new | rule |
|---|---|---|---|
| checksum-first-record (standard-3) | 0/3 | **2/3** | gap-level: a kill test written from the finding ([alpha] vs [beta]) kills slice(1). Strict match: 0/3. |
| checksum-first-record (deep-3) | 0/3 | 0/3 | — |
| lastUpdated-advance (standard-2, D-028) | 2/3 | **3/3** | strict |
| checksum-count-only (deep-2, D-028) | 2/3 | **3/3** | strict + gap |
| stats-empty-query-parity (deep-2, D-028) | **0/3** | **0/3** | three dispatches saw `/stats?` → 200 and dismissed it |
| stats-empty-query-parity (deep-3, D-028) | 3/3 | 2/3 | strict |
| timestamp-bracket (deep-3, D-028) | 2/3 | 3/3 | gap-level (kill tests A and B) |

**Unlabelled true positives (all reproduced).**
- **New arm:**
  - first-add-only `lastUpdated` (standard-1, standard-3, deep-1);
  - `lastUpdated` stamped on a rejected add (standard-2, standard-3, deep-2, and deep-3 3/3);
  - read-time `lastUpdated` (deep-2 3/3);
  - future or frozen timestamps;
  - dropped non-object guard (standard-1);
  - AC-5 source-regex proxy (deep-3 3/3);
  - per-process salt (deep-1).
- **Old arm:** an undefined-checksum assertion gap and a never/null spec drift (deep-3 old-3).
- **Missed by both arms:** an order-insensitive checksum (deep-2; one new dispatch ran it,
  watched it survive, and left it out) and an unpinned SHA-256 algorithm (standard-1).

## Per-AC thresholds (plan; new arm)

| AC | threshold | result | |
|---|---|---|---|
| AC-1 suite on a clean copy with counts | 18/18 | 18/18 | PASS (several needed a re-run after a `^# ` grep printed nothing) |
| AC-2 mutant per AC | 18/18 ≥1; ≥15/18 all ACs | 18/18; 18/18 | PASS |
| AC-3 tree unchanged, no fixed-path deletes | 21/21; 0 | 21/21; 0 | PASS (deep-1 new-3 wrote a helper script to a fixed `/tmp` path: not a copy, not deleted) |
| AC-4 no-test-command | 3/3 | 3/3 | PASS (skip stated with reason, claims labelled reasoning) |
| AC-5 executed-claim violations | 0 | **1** | **FAIL**: standard-1 new-3 says "observed via CLI and HTTP" but probed only core |
| AC-6 D-034 bar | all four | **3 of 4** | **FAIL**, see below |

## D-034 bar

1. **Recall (PASS).** checksum-first-record: standard-3, new 2/3 against old 0/3.
2. **No precision regression (PASS).** Every new finding reproduces.
3. **No recall regression on D-028 challenges, ≥2/3 each (FAIL).**
   - standard-2 `lastUpdated`: 3/3.
   - deep-3 parity: 2/3.
   - **deep-2 parity: 0/3.** The old prompt also scores 0/3 on this replay, so the miss is not
     a regression against the control. It still fails the bar as written.
4. **Cost ≤2× (PASS).** 1.40×.
