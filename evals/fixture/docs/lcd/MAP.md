# Project map — records-sandbox

> Frozen fixture state for the eval harness. Small on purpose.

## Zones

| Zone | Path | What lives here |
|---|---|---|
| core | `core.js` | the single in-memory records store (add/list/clear + VERSION) |
| cli | `cli.js` | CLI surface: `add <text>`, `list`, `version` |
| server | `server.js` | HTTP surface: `GET /records`, `POST /records`, `GET /version` |
| tests | `tests/*.test.js` | node:test suite covering all three zones |

## Entry points

- `node cli.js <command>` — CLI surface
- `node server.js` — HTTP surface (listens on `$PORT` or 3000; `createServer()` exported for tests)
- `node --test tests/` — the gate

## Surfaces in use: CLI, HTTP, none

## Invariants

- **Zero external dependencies** — plain Node.js only; no `dependencies` key ever appears in `package.json`.
- **Both surfaces share `core.js`** — neither `cli.js` nor `server.js` holds records state of its own.
- **Identical behavior across surfaces** — any operation added to one surface must exist on the other with the same semantics, backed by the same core function.
