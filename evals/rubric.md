# Quality rubric — benchmark workspaces (persisted artifact, T1-5.1)

> Every campaign's quality claim must point at a scoring file under `evals/quality/`, produced
> by applying THIS rubric to each workspace. Earlier campaigns (T1 2026-08-22/28, Standard
> 2026-08-30) reported rubric totals from reviewer transcripts only; those numbers are not
> reproducible and are superseded by the first scoring file that covers their workspaces.

## The task under test (all arms)

`stats` operation on the fixture, exposed via CLI **and** HTTP: record count, last-updated
indicator, checksum over the records; validation and error semantics identical on both
surfaces; shared logic in the core module both surfaces already use; full suite green.

## Five dimensions, 0–5 each (25 per workspace)

| # | Dimension | 5 | 3 | 1 |
|---|---|---|---|---|
| 1 | **Completeness** | count + last-updated + checksum on BOTH surfaces, suite green | one field or surface partial | one surface missing or suite red |
| 2 | **Cross-surface parity** | same validation, same error codes/messages/shape on CLI and HTTP, and a test asserts it | parity by inspection only, or one divergence | contradictory semantics |
| 3 | **Shared logic** | stats computed once in `core.js`; surfaces are thin adapters | duplication of a piece (e.g. checksum) in one surface | logic re-implemented per surface |
| 4 | **Test quality** (mutation lens) | tests fail on injected defects in count / last-updated / checksum / error path (≥3 of 4 caught) | 2 of 4 caught | ≤1 caught, or tests assert only existence/no-throw |
| 5 | **Code quality** | fits fixture conventions (node:test, zero deps, existing envelope), no dead code, no invented API surface | minor style drift or one unused helper | breaks fixture conventions or adds deps |

## Two lenses per workspace (independent judges)

- **Inspection** — read `core.js`, `cli.js`, `server.js`, `tests/*` and the diff since tag
  `eval-baseline`; score 1–5 with `file:line` evidence per dimension; dimension 4 by reading
  the assertions (would a stub pass?).
- **Mutation** — copy the workspace to a scratch dir, inject the four defects below one at a
  time, run `node --test`, record which ones the suite catches; score dimension 4 from the
  count and the others from what the mutation work exposed.
  1. count off by one · 2. last-updated frozen/constant · 3. checksum ignores one record ·
  4. error path on one surface returns success (or a different code than the other surface)

Judges never see each other's scores. A workspace's score is the mean of the two lenses;
a campaign's score is the sum over its workspaces (3 runs → /75).

## Scoring file format (`evals/quality/<date>-<campaign>.md`)

One table per lens: `workspace · arm · d1 · d2 · d3 · d4 · d5 · total · key evidence`, then a
`## Means` block (per arm, per lens, and combined) and a `## Mutation matrix` (workspace ×
defect → caught/survived). Rows are comparable only within one model id (D-015).
