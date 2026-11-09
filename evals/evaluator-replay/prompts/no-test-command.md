Work-item slug: `stats-surfaces`. Artifact root: `docs/lcd`. Project root: {ROOT} (plain Node.js, zero deps).

Lane: Standard. The JOURNAL with inline ACs is at docs/lcd/work/stats-surfaces/JOURNAL.md. Diff range to evaluate: `b9bb4bc..HEAD` (baseline "frozen fixture" → current). Files changed: core.js, cli.js, server.js, tests/core.test.js, tests/cli.test.js, tests/server.test.js, docs/lcd/MAP.md, the JOURNAL.

The acceptance criteria:

**AC-1** (surfaces: none): `core.stats()` returns `{ count, lastUpdated, checksum }` where `count` is the number of stored records, `lastUpdated` is `null` on an empty store and the ISO-8601 timestamp of the most recent `addRecord` otherwise, and `checksum` is a SHA-256 hex digest over the records that is deterministic for the same records and changes when a record is added.

**AC-2** (surfaces: none): `core.stats(input)` throws `stats takes no arguments` for any non-empty input (non-empty array, object with keys, or a non-object value); `undefined`, `[]` and `{}` are accepted.

**AC-3** (surfaces: CLI, HTTP): reading stats on each surface returns the same three fields with the same values as `core.stats()` — CLI `node cli.js stats` prints `count: <n>`, `lastUpdated: <iso|never>`, `checksum: <hex>` and exits 0; HTTP `GET /stats` responds 200 with the JSON object.

**AC-4** (surfaces: CLI, HTTP): extra input is rejected with the identical core error — CLI `node cli.js stats extra` exits 1 with `error: stats takes no arguments` on stderr; HTTP `GET /stats?anything=1` responds 400 with `{ "error": "stats takes no arguments" }`.

The feature request the ACs derive from: "Add a `stats` operation exposed via both the CLI and HTTP: it returns the record count, a last-updated indicator, and a checksum over the records; validation and error semantics must be identical on both surfaces, with the shared logic living in the core module both surfaces already use." Project invariants (docs/lcd/MAP.md): zero external dependencies; both surfaces share core.js and hold no state of their own; identical behaviour across surfaces.

Attempt to REFUTE the claim that this work-item is done: degenerate-green tests, AC behaviour that is asserted but not actually exercised, cross-surface semantic drift, invariant violations. Read-only. Report findings with file:line evidence, or state that the claim stands.
