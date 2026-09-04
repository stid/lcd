# Quality scoring — verified claude-fable-5 workspaces (2026-09-04, rubric v1)

> First application of `evals/rubric.md` as a persisted artifact. Covers the nine workspaces
> behind the T1 rerun (2026-08-28, `*-r2`: Deep `lcd` ×3, bare `none` ×3) and the Standard
> campaign (2026-08-30, `std-run1..3`). Supersedes the transcript-only totals quoted in
> `results.md` for those campaigns (T1's 69/75 vs 72/75 was scored on the INVALIDATED
> 2026-08-22 workspaces; Standard's 69–71/75 had no artifact). 18 independent judges (one
> inspection, one mutation per workspace); none saw another's score. Model of the runs:
> `claude-fable-5`.

## Means

| arm | inspection (mean/25) | mutation (mean/25) | combined (mean/25) | campaign /75 |
|---|---|---|---|---|
| deep | 22.0 (21, 23, 22) | 23.3 (22, 25, 23) | 22.7 | 68 |
| standard | 22.7 (22, 23, 23) | 23.7 (23, 24, 24) | 23.2 | 70 |
| none | 21.7 (21, 23, 21) | 23.3 (23, 23, 24) | 22.5 | 68 |

## Inspection lens

| workspace | arm | d1 | d2 | d3 | d4 | d5 | total | key evidence |
|---|---|---|---|---|---|---|---|---|
| 20260828-173311-lcd-r2 | deep | 5 | 4 | 5 | 3 | 4 | **21** | d1 cli.js:36-39 + server.js:43 emit count/lastUpdated/checksum; npm test 26/26 green · d2 shared STATS_INPUT_ERROR core.js:39; AC-4 tests stats.test.js:112-123 assert msg both sides; but GET /stats?x=1 passes while `stats x` errors · d3 getStats core.js:45-51  |
| 20260828-174601-lcd-r2 | deep | 5 | 5 | 5 | 4 | 4 | **23** | d1 core.js:43-52 count/lastUpdated/checksum; cli.js:31-42; server.js:38-46; 25/25 pass · d2 both forward input to core.getStats (cli.js:33, server.js:40); same msg asserted stats.test.js:137,143,153; HTTP==core :131 · d3 core.js:43-52 single impl; surfaces for |
| 20260828-175608-lcd-r2 | deep | 5 | 4 | 5 | 4 | 4 | **22** | d1 cli.js:36-39 + server.js:43 emit count/lastUpdated/checksum; suite 27/27 green · d2 stats.test.js:118-131 AC-4 both surfaces == core.getStats(); errors differ in text (cli.js:33 vs server.js:40) · d3 core.js:32-38 sole computation; surfaces format only · d4 |
| 20260828-174356-none-r2 | none | 5 | 3 | 5 | 4 | 4 | **21** | d1: cli.js:31-37 + server.js:38-41 expose count/lastUpdated/checksum; 25/25 pass. d2: no input so no validation; no test compares CLI vs HTTP output (cli.test.js:32-39 vs server.test.js:52-56) — parity by inspection. d3: core.js:31-37 single getStats; surfaces |
| 20260828-175344-none-r2 | none | 5 | 4 | 5 | 4 | 5 | **23** | d1: cli.js:31-37 + server.js:38-41 expose count/lastUpdated/checksum; suite 25 pass. d2: both call core.getStats; server.test.js:66 deepEquals core, cli.test.js:53-55 only format-checks, no CLI-vs-HTTP test. d3: core.js:31-40 single impl, surfaces thin. d4: co |
| 20260828-180846-none-r2 | none | 5 | 3 | 5 | 3 | 5 | **21** | d1: core.js:30-36 count/lastUpdated/checksum; cli.js:31-37; server.js:38-41; suite 25/25 green. d2: no error path or cross-surface parity test; CLI 'never' vs HTTP null (cli.js:34) is inspection-only. d3: getStats only in core.js:30; surfaces one-call adapters |
| std-run1 | standard | 5 | 4 | 5 | 4 | 4 | **22** | d1 core.js:41-47 count/lastUpdated/checksum; cli.js:31-37; server.js:38-41; 27/27 pass. d2 server.test.js:100-110 asserts CLI==HTTP values; no error/validation path defined or tested for stats. d3 getStats only in core.js:41; surfaces format only. d4 core.test |
| std-run2 | standard | 5 | 4 | 5 | 4 | 5 | **23** | d1 core.js:31-37 getStats; cli.js:31-37; server.js:38-41; suite 22/22 green. d2 server.test.js:70-82 asserts CLI text == HTTP values (empty store only); null->'never' shape diverges; no error-path test for stats. d3 core.js:31-37 sole impl, surfaces format onl |
| std-run3 | standard | 5 | 4 | 5 | 4 | 5 | **23** | d1: cli.js:31-37 + server.js:38-41 expose count/lastUpdated/checksum; suite 28/28 green · d2: both call core.getStats(); AC-4 tests (cli.test.js:88-98, server.test.js:83-88) equal core only transitively; null→'never' cli.js:34; no direct CLI↔HTTP test · d3: co |

## Mutation lens

| workspace | arm | d1 | d2 | d3 | d4 | d5 | total | key evidence |
|---|---|---|---|---|---|---|---|---|
| 20260828-173311-lcd-r2 | deep | 5 | 4 | 5 | 3 | 5 | **22** | d1: core.js:45-51 getStats; cli.js:31-41; server.js:38-45; 26/26 green. d2: shared STATS_INPUT_ERROR core.js:39, asserted stats.test.js:116,123; CLI exit1 vs HTTP 405 (semantic stretch), parity indirect. d3: single getStats core.js:45, surfaces format only. d4 |
| 20260828-174601-lcd-r2 | deep | 5 | 5 | 5 | 5 | 5 | **25** | d1: core.js:43-52 getStats; cli.js:31-42 + server.js:38-46 expose all 3 fields; 25/25 pass · d2: both surfaces forward input to core (cli.js:33, server.js:40); AC-7 CLI/HTTP assert same 'stats takes no input' msg + non-success codes (stats.test.js:137,153); AC |
| 20260828-175608-lcd-r2 | deep | 5 | 4 | 5 | 5 | 4 | **23** | d1: core.js:32-38 getStats; cli.js:31-41; server.js:38-45; 27/27 green · d2: stats.test.js:121-134 AC-4 both surfaces == core; error msgs differ cli.js:33 vs server.js:40, no cross-surface error test · d3: only core.js:36 computes checksum; surfaces format onl |
| 20260828-174356-none-r2 | none | 5 | 3 | 5 | 5 | 5 | **23** | d1 core.js:31-37 count/lastUpdated/checksum; cli.js:31-37; server.js:38-41; 25/25 green · d2 no stats validation on either surface; server.test.js:55 asserts HTTP==core, cli.test.js:32-39 checks format only, no CLI-vs-HTTP assertion · d3 single getStats core.j |
| 20260828-175344-none-r2 | none | 5 | 3 | 5 | 5 | 5 | **23** | d1 core.js:31-40 getStats; cli.js:31-37 stats; server.js:38-41 GET /stats; 25/25 green · d2 no CLI-vs-HTTP assertion; server.test.js:66 deepEq core only; cli.test.js:53-55 format regex only · d3 stats computed once core.js:31-40, surfaces pass-through · d4 ccs |
| 20260828-180846-none-r2 | none | 5 | 4 | 5 | 5 | 5 | **24** | d1 core.js:30-36 getStats; cli.js:31-37; server.js:38-41; 25/25 green · d2 server.test.js:51 HTTP==core.getStats(); cli.test.js:36-38 same fields; no CLI-vs-HTTP assert; stats has no input to validate · d3 single getStats in core.js:30; cli/server only format/ |
| std-run1 | standard | 5 | 4 | 5 | 5 | 4 | **23** | d1: core.js:41-47 count/lastUpdated/checksum; cli.js:31-37; server.js:38-41; 27/27 green · d2: server.test.js:100-110 asserts CLI==HTTP values; CLI prints 'never' for null (cli.js:34); no stats error path exists so no error-parity test · d3: getStats only in c |
| std-run2 | standard | 5 | 4 | 5 | 5 | 5 | **24** | d1: cli.js:31-37 + server.js:38-41 expose count/lastUpdated/checksum; suite 22/22 green. d2: parity test server.test.js:70-82 asserts CLI==HTTP values but only on empty store; stats has no error path. d3: core.js:31-37 getStats is sole impl; surfaces call core |
| std-run3 | standard | 5 | 4 | 5 | 5 | 5 | **24** | d1 core.js:31-37 count/lastUpdated/checksum; cli.js:31-37 + server.js:38-41 expose it; 28/28 green · d2 no direct CLI-vs-HTTP test; parity transitive via AC-4 cli.test.js:88-98 and server.test.js:83-88 vs core.getStats(); null->'never' cli.js:34 · d3 stats com |

## Mutation matrix

| workspace | arm | D1 count | D2 last-updated | D3 checksum | D4 error path |
|---|---|---|---|---|---|
| 20260828-173311-lcd-r2 | deep | caught | **survived** | **survived** | caught |
| 20260828-174601-lcd-r2 | deep | caught | caught | caught | caught |
| 20260828-175608-lcd-r2 | deep | caught | caught | **survived** | caught |
| 20260828-174356-none-r2 | none | caught | caught | caught | caught |
| 20260828-175344-none-r2 | none | caught | caught | **survived** | caught |
| 20260828-180846-none-r2 | none | caught | caught | **survived** | caught |
| std-run1 | standard | caught | caught | caught | caught |
| std-run2 | standard | caught | caught | caught | caught |
| std-run3 | standard | caught | caught | **survived** | caught |

## Judge notes (what the score hides)

- `20260828-173311-lcd-r2` (deep, inspection): No test asserts lastUpdated advances between adds or a non-empty exact checksum; defects 2 and 3 likely survive. Unrequested VERSION-from-package.json + 1.1.0 bump.
- `20260828-173311-lcd-r2` (deep, mutation): D2: cruder variant (constant returned in getStats) IS caught by AC-6; frozen-after-first-mutation survives since no test asserts the stamp advances. Checksum never asserted against a computed expected on non-empty store.
- `20260828-174601-lcd-r2` (deep, inspection): Scratch-copy mutation check: count+1, frozen lastUpdated, drop-last/middle checksum, HTTP 200-on-error, CLI exit 0 all caught; drop-first-record checksum survives (no non-empty checksum pinned).
- `20260828-174601-lcd-r2` (deep, mutation): M3 variant 'ignore first record' (slice(1)) survives: AC-2 only pins empty checksum + text/order diffs, never a multi-record literal. lastUpdated is a mutation seq (D-002), not a timestamp.
- `20260828-175608-lcd-r2` (deep, inspection): Checksum test never pins a value or compares empty-vs-one; a hash dropping first/last record passes. 405 on /stats is a new pattern (other routes 404 on wrong method). Version bump out of scope.
- `20260828-175608-lcd-r2` (deep, mutation): Checksum tests only assert hex64+determinism+changes-on-add; a checksum skipping any single record passes. Version bump/VERSION source change is scope drift outside the task.
- `20260828-174356-none-r2` (none, inspection): Checksum tests only use 0-vs-1 record; a defect hashing only the first record would survive. CLI stats always 0/never (per-process store) so CLI test is weak on values.
- `20260828-174356-none-r2` (none, mutation): M2 variant "frozen after first write" (lastUpdated ??= now) SURVIVED; M4 caught only by pre-existing baseline tests (stats has no error path). CLI stats never tested with count>0 (fresh process).
- `20260828-175344-none-r2` (none, inspection): Stats has no input so parity is trivially strong. Checksum-ignores-FIRST-record would survive (core.test.js:70 only detects last-record drop); CLI checksum never compared to core value.
- `20260828-175344-none-r2` (none, mutation): Checksum never pinned to a value on any surface. Alt variants also survive: lastUpdated frozen after first add; CLI error exit 1->2 (only non-zero asserted). Stats op has no input so no validation to diverge.
- `20260828-180846-none-r2` (none, inspection): Checksum test asserts only "changes after add" so a hash that drops one record still passes; stats has no input so error-parity is vacuous, not tested. Server test deepStrictEqual vs core.getStats() is self-referential.
- `20260828-180846-none-r2` (none, mutation): Checksum coverage gap: no test pins checksum to a known sha256 or detects a dropped record. D2 caught by only one test (core). cli.test.js:41 test name misleading (runs 'bogus').
- `std-run1` (standard, inspection): Defect 4 not applicable: stats has no input so no error path exists on either surface; error parity only covered by pre-existing add tests. CLI prints 'never' for null lastUpdated (formatting only).
- `std-run1` (standard, mutation): D2 variant 'frozen after first add' SURVIVES (no test checks lastUpdated changes on 2nd add). D2/D3 caught only by core tests, not surface tests. D4 caught only by pre-existing fixture tests.
- `std-run2` (standard, inspection): No golden checksum value: sha256(count) stub passes all tests. No assertion that lastUpdated advances between adds. Parity test covers only empty state (CLI is process-per-run). Comma-op at core.test.js:70.
- `std-run2` (standard, mutation): Variant 'lastUpdated frozen at a constant ISO date' survived (tests only match ISO shape, never that it changes). Parity test covers empty store only, so a record-skipping checksum would not break parity.
- `std-run3` (standard, inspection): Checksum-ignores-first-record would survive (only last-record omission caught). Stats has no input so error parity rests on pre-existing usage/404 tests. runInProcess monkeypatches console.log.
- `std-run3` (standard, mutation): Checksum tests assert determinism only; dropping a record from the hash survives all 3 suites. D2 caught only by core test (timestamp bound), surface tests check format only. Stats has no input so no stats-specific error path exists.
