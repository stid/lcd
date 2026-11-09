Project root: {ROOT}
Artifact root: docs/lcd
Work-item slug: stats-surfaces (Deep lane), branch feat/stats-surfaces
Diff range to evaluate: 678eb6e..HEAD  (baseline commit 678eb6e "baseline: frozen fixture" → HEAD)

Claim under test: the work-item is DONE — audit passed 10/10 rows OK and `node --test tests/` is green (28/28).

Your job is to try to REFUTE that claim. Read docs/lcd/work/stats-surfaces/spec.md (AC-1 … AC-7), plan.md, and the diff (`git diff 678eb6e..HEAD`), then check with file:line evidence:
- Is any AC's promised behaviour untested (test carries the literal but does not actually assert the AC body)? In particular: AC-2 "both surfaces report exactly the same three values", AC-4 checksum stability/change, AC-5 identical error message on both surfaces, AC-6 "any changed, added or removed record → different value", AC-7 clear resets.
- Is any test degenerate green (always-true assertion, mocks the thing under test, order-dependent, timing-flaky)?
- Do CLI and HTTP actually share core.getStats with no surface-local logic (MAP invariant)?
- Anything in the diff outside the JOURNAL EDIT BOUNDARY, or a behaviour regression to existing add/list/version routes?
- Run `node --test tests/` yourself to confirm green, and any ad-hoc `node -e` probe you find useful.

Report: verdict `stands` or `challenged (<n> findings)`, then each finding as file:line + one-sentence why it matters + severity. Read-only; do not edit anything.
