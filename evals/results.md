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

## T1 campaign conclusion (2026-08-22) — lcd vs none (bare agent), claude-fable-5

First run of the baseline arm (v0.17.0). 3 runs/arm, alternating, sequential. Isolation:
settings-only (`--settings '{"enabledPlugins":[]}'` via an `EVAL_CLAUDE_BIN` wrapper) —
`CLAUDE_CONFIG_DIR` isolation broke auth on the host (Keychain bound to the default config
identity), so the operator's user-global CLAUDE.md loaded in BOTH arms symmetrically; it
mandates TDD, which if anything strengthens the baseline arm.

**Cost/tokens (rows above):** lcd mean 4.93M tok / $8.89 (range $7.80–$10.32); none mean
0.85M tok / $1.98 ($1.64–$2.27). Ranges do not overlap: the bare agent completed the same
feature at **~4.5× lower cost, ~5.8× fewer tokens, ~2.5× less wall-clock**. All 6 runs
finished green (lcd: audit PASS 0 non-OK ×3; none: EVAL-DONE + suite green ×3).

**Quality (rubric review of all 6 workspaces — completeness / cross-surface parity /
shared-logic / test quality / code quality, independent reviewers, file:line evidence):**
near-parity. lcd 69/75, none 72/75. All 6 runs: complete feature, logic correctly placed
once in core, style-conformant, suite green. Differences worth recording:
- All 3 lcd runs *invented* an input-validation contract for `stats` ("stats takes no
  input", rejected on both surfaces, explicit parity tests) — and all 3 then carried minor
  parity drift *inside that invented path* (query-string vs argv asymmetry ×3, a 405/message
  conflation, an empty-string edge). The 3 none runs read `stats` as accepting no input
  (consistent with the fixture's `list`), making parity vacuous and defect-free. The spec
  phase manufactured requirement surface area, then imperfectly satisfied it.
- lcd test suites asserted cross-surface parity explicitly (2 of 3 directly); none suites
  asserted surface-to-core equivalence (transitive parity) — slightly weaker as evidence,
  same observed outcomes here.
- Implementation variance was HIGHER under lcd: checksum sha256+ISO in 2 runs but FNV-1a +
  mutation-counter in 1; all 3 none runs converged on the same natural design (sha256 over
  JSON.stringify, ISO timestamp). n=3 — a signal to watch, not a finding.

**What this campaign does NOT show:** single-shot only — LCD's core claims (cheap cold
pickup, multi-session drift control, decision durability) are structurally unmeasurable in
this design and remain untested (→ T1b longitudinal benchmark, dev harness
PROPOSALS-2026-08). Interventions unmeasured (n/a; → T2). One fixture, one task class (small,
well-specified, two-surface), one model. The lcd arm's spend also produced durable process
artifacts (spec/plan/journal/audit) whose downstream value is exactly what T1b would price.

**Honest single-shot verdict:** on this task class, the full Deep pipeline cost ~4.5× and
bought no measurable single-shot quality advantage. Whatever case exists for LCD rests on
multi-session value — currently unmeasured — not on single-shot output quality.
