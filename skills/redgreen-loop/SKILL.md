---
name: redgreen-loop
description: Autonomous build verb of LCD. Use when an LCD work-item (docs/lcd/work/<slug>/ or the conventions artifact-root) has failing tests to drive to green — after Deep-lane test-gen, or once a Standard-lane JOURNAL's STEPS reach failing tests. Iterates the test runner with bail, fixes the first failing test with minimum code, commits, repeats until green. Hard iteration cap and stuck escalation.
user-invocable: false
---

# Red-Green Loop (LCD build verb)

Drives the inner TDD loop autonomously once failing tests exist (Deep-lane phase 4, or a
Standard-lane JOURNAL whose STEPS reached failing tests), escalating via `STUCK.md` if it can't make
progress. The **edit boundary comes from the JOURNAL EDIT BOUNDARY** (Deep lane keeps it in sync with
`plan.md`'s File structure) — that boundary bounds every edit the loop is allowed to make.

## Resolve paths + toolchain

Resolve the artifact root from `.claude/rules/lcd-conventions.md` (`artifact-root`, default
`docs/lcd`). Work item: `<artifact-root>/work/<slug>/`. Pick the test runner from the lockfile — you
need a **full-suite** command, a **bail** command (stop on first failure), and a **single-test**
filter:

| Marker | suite | bail | single test |
| ------ | ----- | ---- | ----------- |
| `bun.lockb` | `bun test` | `bun test --bail` | `bun test --bail -t '<name>'` |
| pnpm/yarn/npm | `<pm> test` | `<pm> test … --bail` | `<pm> test -- -t '<name>'` |
| `Cargo.toml` | `cargo test` | `cargo test` | `cargo test <name>` |
| `pyproject.toml`/`requirements.txt` | `pytest` | `pytest -x` | `pytest -x -k '<name>'` |
| `go.mod` | `go test ./...` | `go test -failfast ./...` | `go test -run '<name>' ./...` |

**Project override:** if `.claude/rules/lcd-conventions.md` exists, its `<!-- lcd-conventions:v1 -->`
block defines `bail` / `single-test` / `gate` — use those over the lockfile defaults. Required when
the bare `<pm> test` enters **watch mode** (vitest/jest), which would hang the loop.

**Monorepo (zone-scoped) override:** the block may also carry `key[<path-prefix>]:` variants
(e.g. `bail[packages/api]: …`). When the EDIT BOUNDARY paths sit under such a prefix, use that
zone's commands; longest matching prefix wins; the bare key is the fallback. If the boundary
spans zones with *different* runners, run each zone's scoped command for its own paths.

## Preconditions

Run only when ALL hold:

1. The work-item exists with a JOURNAL (`<artifact-root>/work/<slug>/JOURNAL.md`); for Deep lane,
   `spec.md`/`plan.md`/`tasks.md` exist too. (`STUCK.md` is allowed but signals a prior halt — read
   it first and decide whether the situation changed.)
2. The JOURNAL **EDIT BOUNDARY** lists every path the loop may edit (Deep: mirrors plan.md File
   structure). If it's empty, halt and ask for it.
3. The scoped test run currently exits non-zero (there is something to fix).

If any precondition fails, halt and tell the user which phase/step to run.

## Knobs (do not negotiate per-run)

| Knob | Setting |
| ---- | ------- |
| Iteration cap | **20** total iterations per invocation |
| Stuck detection | **(a)** Same failing test + same assertion error twice consecutively, OR **(b)** the last fix diff is byte-identical to a prior attempt |
| Escalation | Write `<artifact-root>/work/<slug>/STUCK.md`. Halt; print the path |
| Commit policy | **One commit per test that flips red→green.** `feat(<slug>): pass AC-N (SURFACE)` or `fix(<slug>): pass AC-N`. On the **branch's first commit**, apply the `versioning` rule — but **verify the manifest's current version on the branch first** (`git show $(git merge-base HEAD <default-branch>):<manifest>`); don't assume a baseline `chore:` commit already bumped it |
| Edit boundary | The loop may ONLY modify paths in the JOURNAL **EDIT BOUNDARY**. Out-of-plan edits abort the iteration immediately and do NOT count against the 20-cap. This is also **enforced structurally**: the plugin's PreToolUse hook (`lcd-boundary-check.sh`) denies out-of-boundary edits while the work-item is active — a denied edit means fix the target (or extend the boundary via `lcd:refine`), never fight the hook |

## The loop

```
iteration = 0
while iteration < 20:
    iteration += 1

    output = run(BAIL_CMD)                     # 1. run suite, stop on first failure
    if exit_code == 0: break                   #    all green → done

    failing_name  = parse_first_failing_test(output)   # 2.
    failing_error = parse_first_assertion_error(output)

    if failing_name == prev_name and failing_error == prev_error:   # 3. stuck (a)
        write_stuck_md(slug, …, "repeat-failure"); halt
    prev_name, prev_error = failing_name, failing_error

    target = pick_target_from_edit_boundary(failing_name)  # 4. read test, then AC in spec/JOURNAL
    diff   = generate_minimum_diff(target, failing_test, failing_error)  # 5.

    if diff in attempted_diffs:                # 6. stuck (b)
        write_stuck_md(slug, …, "repeat-diff"); halt
    attempted_diffs.append(diff)

    if any_path_in(diff) not in edit_boundary: # 7. edit-boundary check
        log("out-of-plan edit; aborting iteration without counting"); iteration -= 1; continue

    apply_diff(diff)                           # 8.
    if run(SINGLE_TEST_CMD for failing_name).exit_code != 0:
        revert_diff(diff); continue            #    didn't fix → try a different approach

    commit(f"feat({slug}): pass {failing_name}")   # 9. one commit per red→green flip
    update_journal_now_and_steps()                 #    keep the resume anchor current

if iteration == 20 and exit_code != 0:
    write_stuck_md(slug, …, "iteration-cap"); halt
```

## Budget-aware variant (under `Workflow` only)

When this loop runs *inside* a `Workflow` script, the script also has a token budget via
`budget.remaining()`, so the guard becomes the **lower of** {20 iterations, budget exhausted,
stuck}. The 20-iteration cap is otherwise unchanged:

```js
// inside a Workflow script — budget is NOT reachable from the in-loop skill
let iteration = 0
while (iteration < 20 && (!budget.total || budget.remaining() > 30_000)) {
    iteration += 1
    // ... same red→green body (bail, fix first failure, single-test gate, commit) ...
}
// halt reason: iteration-cap | budget-exhausted | stuck — write STUCK.md, then escalate
```

`budget` only exists inside a `Workflow`; in the plain skill the cap + stuck detection stay the
sole bounds.

## Implementation tactics

- **Read the test first, then the AC.** The test is the contract; the AC body (spec.md, or the
  JOURNAL ACs for Standard lane) is the why. If the test asks for something the AC didn't promise,
  stop — fix the test rather than implement the wrong thing.
- **Minimum code only.** If the test asserts `response.version === string`, the impl is a one-line
  `return { version: VERSION }` — not a refactor, not validation. The audit catches missing surfaces;
  resist scope creep.
- **Use existing primitives.** Grep (start from MAP Zones) before adding a helper.
- **Keep the JOURNAL current.** After each green commit, tick the STEP and update NOW.Next-action —
  this is what makes a mid-loop context reset resumable via `/lcd:resume`.

## Writing STUCK.md

Start from the LCD package's `templates/STUCK.md` and fill in: exact failing test name (as the
runner printed it); the full assertion error block; the last three attempted diffs (unified
format); the edit boundary (copy from the JOURNAL); a `last attempted` timestamp. Then halt. Don't
use `AskUserQuestion` — the user may be away. STUCK.md
plus the JOURNAL is enough for a cold pickup.

## When to stop early (not via STUCK)

- All scoped tests pass AND the full suite is green → success. Report iterations used.
- The user interrupts with a redirect → halt immediately.

## Quality gate before declaring done

- Final full-suite run exits 0.
- Per-fix commits exist (one per test that flipped).
- No unacknowledged `STUCK.md`.
- JOURNAL NOW.Next-action updated, and the **iterations used recorded as a JOURNAL LOG line**
  (e.g. `red-green: green in 4 iterations, 0 reverts`) — the work-item's closeout reads it.
  Suggest `/lcd:audit <slug>` next (if a surface was declared).
