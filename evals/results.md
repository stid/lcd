# Eval results — one row per benchmark run (append-only)

<!-- date · arm · workspace · audit (non-OK rows) · suite · commits (redgreen) · tokens · interventions · model -->
<!-- Rows are comparable only within the same model id (D-015): a model change resets the
     baseline — never A/B across model boundaries. Rows before 2026-07-08 predate the per-row
     stamp; they all ran the pinned experiment model claude-fable-5 (EVAL_CLAUDE_MODEL default). -->
2026-06-11 · A · 20260611-005255-A · audit: PASS (0 non-OK) · suite: green · commits: 11 (redgreen: 4) · tokens: 154930 · interventions: n/a
2026-06-11 · B · 20260611-010456-B · audit: PASS (0 non-OK) · suite: green · commits: 12 (redgreen: 6) · tokens: 160293 · interventions: n/a
2026-06-11 · A · 20260611-012011-A · audit: PASS (0 non-OK) · suite: green · commits: 9 (redgreen: 3) · tokens: 151076 · interventions: n/a
2026-06-11 · B · 20260611-012005-B · audit: PASS (0 non-OK) · suite: green · commits: 13 (redgreen: 7) · tokens: 151855 · interventions: n/a
2026-06-11 · B · 20260611-013344-B · audit: PASS (0 non-OK) · suite: green · commits: 10 (redgreen: 3) · tokens: 128273 · interventions: n/a
2026-06-11 · A · 20260611-013338-A · audit: PASS (0 non-OK) · suite: green · commits: 9 (redgreen: 3) · tokens: 148749 · interventions: n/a
2026-06-11 · C · 20260611-015752-C · audit: PASS (0 non-OK) · suite: green · commits: 9 (redgreen: 3) · tokens: 144681 · interventions: n/a
2026-06-11 · C · 20260611-015758-C · audit: PASS (0 non-OK) · suite: green · commits: 14 (redgreen: 4) · tokens: 38982 · interventions: n/a

## Metric v2 re-grade (2026-06-11)

The v1 `tokens` metric had two bugs, found when a fan-out run reported 4x cheap: it read
`.usage` (main agent only — subagent fan-out usage invisible) and counted cache creation but
not reads (a run riding a concurrent run's prompt cache looked cheap; scheduling-dependent).
v2 = `modelUsage` volume (in + cache-creation + cache-read + out, all models, all legs;
scheduling-invariant) + `cost` (total_cost_usd). Rows above are v1 and kept for the record;
the same workspaces re-graded:

2026-06-11 · A · 20260611-005255-A · audit: PASS (0 non-OK) · suite: green · commits: 11 (redgreen: 4) · tokens: 4219667 · cost: $8.37 · interventions: n/a
2026-06-11 · B · 20260611-010456-B · audit: PASS (0 non-OK) · suite: green · commits: 12 (redgreen: 6) · tokens: 5360647 · cost: $9.78 · interventions: n/a
2026-06-11 · B · 20260611-012005-B · audit: PASS (0 non-OK) · suite: green · commits: 13 (redgreen: 7) · tokens: 5439834 · cost: $9.71 · interventions: n/a
2026-06-11 · A · 20260611-012011-A · audit: PASS (0 non-OK) · suite: green · commits: 9 (redgreen: 3) · tokens: 5490801 · cost: $9.65 · interventions: n/a
2026-06-11 · A · 20260611-013338-A · audit: PASS (0 non-OK) · suite: green · commits: 9 (redgreen: 3) · tokens: 4396314 · cost: $8.64 · interventions: n/a
2026-06-11 · B · 20260611-013344-B · audit: PASS (0 non-OK) · suite: green · commits: 10 (redgreen: 3) · tokens: 4175610 · cost: $7.69 · interventions: n/a
2026-06-11 · C · 20260611-015752-C · audit: PASS (0 non-OK) · suite: green · commits: 9 (redgreen: 3) · tokens: 5128689 · cost: $9.17 · interventions: n/a
2026-06-11 · C · 20260611-015758-C · audit: PASS (0 non-OK) · suite: green · commits: 14 (redgreen: 4) · tokens: 5988200 · cost: $11.53 · interventions: n/a

Means (v2): A 4,702,261 tok / $8.89 · B 4,992,030 tok / $9.06 — the v1 "B ~3% lower" token
claim does NOT survive the metric fix (direction flips to ~6% A, still within noise; ranges
overlap, B holds the single cheapest run). Quality parity (the D-009 primary basis) unchanged.
C2 ran the async worktree fan-out path (surface branches + reviewer) — legitimate Deep-lane
variance; its true cost was the highest of the set.
2026-06-11 · C · 20260611-021641-C · audit: PASS (0 non-OK) · suite: green · commits: 12 (redgreen: 6) · tokens: 5445361 · cost: $10.26 · interventions: n/a
2026-07-20 · fanout-extract-0.12.0 · 20260720-213945-fanout-extract-0.12.0 · audit: PASS (0 non-OK) · suite: green · commits: 9 (redgreen: 3) · tokens: 4658031 · cost: $8.22 · interventions: n/a · model: claude-fable-5
2026-08-22 · lcd · 20260822-173937-lcd · audit: PASS (0 non-OK) · suite: green · commits: 9 (redgreen: 3) · tokens: 4161986 · cost: $7.8 · interventions: n/a · model: claude-fable-5
2026-08-22 · none · 20260822-175007-none · audit: n/a (n/a non-OK) · suite: green · commits: 5 (redgreen: 0) · tokens: 927005 · cost: $2.03 · interventions: n/a · model: claude-fable-5
2026-08-22 · lcd · 20260822-175434-lcd · audit: PASS (0 non-OK) · suite: green · commits: 9 (redgreen: 3) · tokens: 6055571 · cost: $10.32 · interventions: n/a · model: claude-fable-5
2026-08-22 · none · 20260822-180922-none · audit: n/a (n/a non-OK) · suite: green · commits: 3 (redgreen: 0) · tokens: 1073425 · cost: $2.27 · interventions: n/a · model: claude-fable-5
2026-08-22 · lcd · 20260822-181407-lcd · audit: PASS (0 non-OK) · suite: green · commits: 13 (redgreen: 6) · tokens: 4565648 · cost: $8.55 · interventions: n/a · model: claude-fable-5
2026-08-22 · none · 20260822-182801-none · audit: n/a (n/a non-OK) · suite: green · commits: 1 (redgreen: 0) · tokens: 538784 · cost: $1.64 · interventions: n/a · model: claude-fable-5

## T1 campaign 2026-08-22 — INVALIDATED (isolation was inert; rows kept for the record)

The 2026-08-22 rows above ran with a schema-invalid plugin-disable flag (`enabledPlugins`
as an array — inert) and no config-dir barrier: all three `none` rows had 13 user-level
plugins INCLUDING lcd loaded (found by the independent closeout evaluator from session
transcripts; the plugin was loaded but demonstrably unused — no methodology artifacts in
any `none` workspace). Rows kept per append-only policy; superseded by the verified rerun
below. Fix: 0.17.1 (schema-valid disable map, real-argv tests).

2026-08-28 · lcd · 20260828-173311-lcd-r2 · audit: PASS (0 non-OK) · suite: green · commits: 9 (redgreen: 3) · tokens: 4862385 · cost: $8.93 · interventions: n/a · model: claude-fable-5
2026-08-28 · none · 20260828-174356-none-r2 · audit: n/a (n/a non-OK) · suite: green · commits: 3 (redgreen: 0) · tokens: 1018656 · cost: $2.08 · interventions: n/a · model: claude-fable-5
2026-08-28 · lcd · 20260828-174601-lcd-r2 · audit: PASS (0 non-OK) · suite: green · commits: 10 (redgreen: 3) · tokens: 4004778 · cost: $7.63 · interventions: n/a · model: claude-fable-5
2026-08-28 · none · 20260828-175344-none-r2 · audit: n/a (n/a non-OK) · suite: green · commits: 4 (redgreen: 0) · tokens: 997111 · cost: $2.17 · interventions: n/a · model: claude-fable-5
2026-08-28 · lcd · 20260828-175608-lcd-r2 · audit: PASS (0 non-OK) · suite: green · commits: 10 (redgreen: 3) · tokens: 5402262 · cost: $10.09 · interventions: n/a · model: claude-fable-5
2026-08-28 · none · 20260828-180846-none-r2 · audit: n/a (n/a non-OK) · suite: green · commits: 3 (redgreen: 0) · tokens: 710751 · cost: $1.77 · interventions: n/a · model: claude-fable-5

## T1 campaign conclusion (2026-08-28, verified isolation) — lcd vs none, claude-fable-5

Rerun under 0.17.1 isolation, empirically probed before spend: with the disable map the
model reports NO lcd skills; with `--plugin-dir` added it reports all 14 — arms differ by
exactly one flag. Plugin under test: released v0.17.0 (worktree). 3 runs/arm, alternating,
sequential. Residual symmetric load: operator's user-global CLAUDE.md (mandates TDD — if
anything strengthens the baseline arm).

**Cost/tokens:** lcd mean 4.76M tok / $8.88 (range $7.63–$10.09); none mean 0.91M tok /
$2.01 ($1.77–$2.17). No overlap: the bare agent completed the same feature at **~4.4× lower
cost, ~5.2× fewer tokens, ~5.1× less wall-clock (lcd ~10.3 min vs none ~2.0 min mean)**. All 6 runs green (lcd: audit PASS ×3;
none: EVAL-DONE + suite green ×3). Means match the invalidated 2026-08-22 campaign within
noise — the contamination's cost effect was negligible, but only this rerun can say so.

**Quality:** the 6-workspace rubric review (completeness / cross-surface parity /
shared-logic / test quality / code quality, independent reviewers, file:line evidence) was
run on the 2026-08-22 workspaces: near-parity, lcd 69/75 vs none 72/75. All runs complete,
core logic correctly placed, green. The lcd runs invented an input-validation contract for
`stats` and drifted inside it (3 minor parity defects); the none runs read stats as
input-less (vacuous parity, defect-free) and converged on one design where lcd runs
diverged (sha256+ISO ×2 vs FNV-1a+counter ×1). The rerun rows are metrically
indistinguishable from the reviewed set; the review was not repeated.

**What this does NOT show:** single-shot only — cold-pickup, multi-session drift control,
and decision durability (LCD's core claims) are structurally unmeasured here (→ T1b
longitudinal benchmark, dev harness). Interventions unmeasured (→ T2). One fixture, one
task class, one model. The lcd arm's spend also bought durable process artifacts whose
downstream value is exactly what T1b would price.

**Honest single-shot verdict (unchanged by the rerun):** on this task class the full Deep
pipeline costs ~4.4× and buys no measurable single-shot quality advantage. LCD's case, if
it exists, is multi-session — currently unmeasured.
2026-08-30 · standard-1 · std-run1 · audit: INCOMPLETE (n/a non-OK) · suite: green · commits: 5 (redgreen: 0) · tokens: 2048493 · cost: $4.34 · interventions: n/a · model: claude-fable-5
2026-08-30 · standard-2 · std-run2 · audit: INCOMPLETE (n/a non-OK) · suite: green · commits: 5 (redgreen: 0) · tokens: 1717075 · cost: $3.8 · interventions: n/a · model: claude-fable-5
2026-08-30 · standard-3 · std-run3 · audit: INCOMPLETE (n/a non-OK) · suite: green · commits: 5 (redgreen: 0) · tokens: 2211118 · cost: $4.4 · interventions: n/a · model: claude-fable-5

## Standard-arm campaign conclusion (2026-08-30, work-item lean-loop) — triage-routed vs the T1 arms, claude-fable-5

Context: the 2026-08-30 over-engineering audit (harness D-026) found T1's prompt *mandated*
the Deep pipeline while triage's own table routes the benchmark task to Standard — so the
4.4× number priced a lane real work rarely enters. This campaign ran the new
`--triage-routed` arm (`feature-prompt-standard.md`, no lane named) 3×, sequential,
settings-only isolation (D-025 fallback wrapper — config-dir isolation breaks keychain auth
on this machine; a first attempt without the wrapper failed all legs "Not logged in" and was
discarded). Plugin under test: released v0.17.1 (installed cache), i.e. WITHOUT this PR's
noise cuts.

**Routing:** 3/3 runs triaged the task to **Standard** (3 signals, hard:no, risk:no) —
confirming the D-026 reframe empirically. All 3 completed the full Standard contract
unprompted: JOURNAL, TDD, test-presence audit PASS, closeout line (re-routes: 0,
interventions: 0). `audit: INCOMPLETE` in the rows is the grader's Deep-artifact check —
by design, not failure; suite green is the completion signal.

**Cost/tokens:** mean 1.99M tok / $4.18 / ~4.7 min (ranges 1.72–2.21M, $3.80–$4.40,
4.1–5.5 min). Against T1's verified arms: **~2.1× bare cost and ~2.2× tokens (vs Deep's
~4.4× / ~5.2×)** — the median lane costs roughly half the Deep pipeline's overhead. One leg
per run (Deep needed multi-leg continues).

**Quality:** two independent reviewers, same 5-dim rubric (one by inspection: 69/75; one by
mutation testing — 4 injected defects per workspace: 71/75). Per-workspace 24/20–22/25;
per-workspace mean 23.3–23.7 sits inside T1's band (Deep 23.0, bare 24.0). Near-parity
again: process weight bought no measurable single-shot quality at ANY tier. Notable: the
three runs converged on one design (byte-identical `cli.js` across all three; single
divergence: run1's un-enveloped HTTP body), where the T1 Deep runs diverged. The spread is
verification depth (run2 wrote 5 new tests vs 11–12; a mutation survives only there).

**What this does NOT show:** same limits as T1 — single-shot, one fixture/task/model;
cold-pickup and multi-session value unmeasured (→ T1b). Ran on 0.17.1: the lean-loop cuts
(closeout collapse, triage slim) should reduce Standard's overhead — re-measure on 0.18.0
is parked in the harness ROADMAP.

**Honest verdict:** the lane the methodology actually picks for this task costs ~2.1× bare
(not 4.4×) at the same near-parity quality, and 3/3 runs produced the durable spine
(JOURNAL, closeout telemetry) whose value T1b prices. The keep/slim/pivot decision now has
the median lane's number.
