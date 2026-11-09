Work-item: `stats-surfaces` (Standard lane). Repo root: {ROOT}. Artifact root: docs/lcd. JOURNAL: docs/lcd/work/stats-surfaces/JOURNAL.md (inline ACs in the "Acceptance criteria" section). Diff range: c0bf5cd..HEAD (baseline `c0bf5cd` = frozen fixture). Gate: `node --test tests/` (currently 27/27 green).

Feature claim: a `stats` operation exposed via CLI (`node cli.js stats`) and HTTP (`GET /stats`) returning record count, a last-updated indicator, and a checksum over the records; validation and error semantics identical on both surfaces, shared logic in core.js (`getStats`).

ACs:
- AC-1 (CLI, HTTP): stats reports count = N, lastUpdated = ISO timestamp of last add (null / "never" when empty), checksum = core checksum of current records — same values core.getStats() returns.
- AC-2 (CLI, HTTP): unexpected parameters (CLI trailing args; HTTP query-string keys) are rejected with core's single error message — CLI exits non-zero with `error: <message>` on stderr, HTTP 400 `{ "error": "<message>" }` — store untouched.
- AC-3 (none): checksum identical for identical content, differs when records change; lastUpdated set by addRecord, reset to null by clear.

Attempt to REFUTE that this work-item is done: look for degenerate-green tests (assertions that can't fail, tautologies against the implementation), AC behaviour with no real test, divergence between CLI and HTTP semantics, MAP invariants violated (zero deps, both surfaces share core, identical behavior across surfaces), and anything in the diff that the tests don't exercise. Read-only. Report `stands` or `challenged (<n> findings)` with file:line evidence for each finding.
