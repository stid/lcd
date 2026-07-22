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
