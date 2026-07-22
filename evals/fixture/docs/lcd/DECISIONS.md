# Decisions — records-sandbox

> Append-only. Never edit or delete an entry; supersede with a new one.

## D-001 — Zero external dependencies (2026-06-11)

The sandbox stays plain Node.js: no `dependencies` key in `package.json`, tests run on the
built-in `node --test` runner. Rationale: the project is copied fresh per benchmark run, so
installs would add time and nondeterminism for zero benefit. Superseding this requires a
new decision entry.
