Project root: {ROOT} (plain Node.js, zero deps; gate is `node --test tests/`).

Work-item slug: stats-surfaces · artifact root: docs/lcd · lane: Standard.
JOURNAL with inline ACs: docs/lcd/work/stats-surfaces/JOURNAL.md
Diff range to evaluate: 411cb21..HEAD (baseline commit 411cb21 "baseline: frozen fixture").

Feature claim: a `stats` operation exposed via CLI (`node cli.js stats [--algorithm <name>]`) and HTTP (`GET /stats[?algorithm=<name>]`) returning record count, a last-updated indicator, and a checksum over the records; validation and error semantics identical on both surfaces; shared logic in core.js (`getStats`).

ACs (from the JOURNAL):
- AC-1 (CLI, HTTP): count = N records (0 on empty).
- AC-2 (CLI, HTTP): lastUpdated = ISO-8601 of most recent addRecord, null when never written.
- AC-3 (CLI, HTTP): checksum = hex digest over records, identical for identical contents (empty → digest of `[]`), reports `algorithm` (default sha256).
- AC-4 (CLI, HTTP): unsupported algorithm → core error `unsupported checksum algorithm: <name>`; CLI exits 1 with `error: <msg>` on stderr; HTTP 400 `{ "error": <msg> }`.

Attempt to REFUTE the claim that this work-item is done: look for degenerate green (tests that would pass without the implementation, tautological assertions), AC behaviour that is untested on a declared surface, divergence between CLI and HTTP semantics, and violations of the MAP invariants in docs/lcd/MAP.md (zero deps; both surfaces share core.js; identical behaviour across surfaces). Run `node --test tests/` yourself. Report evidence-grounded findings with file:line, and end with a verdict line: `evaluator: stands` or `evaluator: challenged (<n> findings)`. Read-only — do not edit anything.
