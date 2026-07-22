# Tasks: <FEATURE_TITLE>

> **Deep lane · Phase 3 of 6 (Tasks).** A flat, dependency-ordered checklist. Each task names
> the file it touches. Tests come before the code they test (TDD). The granular STEPS in the
> work-item `JOURNAL.md` mirror this list as the resume view; keep them in sync.

**Slug:** `<SLUG>`
**Spec:** [`spec.md`](./spec.md) • **Plan:** [`plan.md`](./plan.md) • **Journal:** [`JOURNAL.md`](./JOURNAL.md)
**Created:** <YYYY-MM-DD>
**Status:** in_progress <!-- in_progress | completed | abandoned -->

---

## Conventions

- `[P]` suffix = parallelizable with the previous task (different file, no shared state).
- Tests precede implementation tasks they cover.
- One file per task where possible; tasks naming multiple files should be split unless the change is genuinely atomic.

## Tasks

> Each test task that covers a cross-path AC should have a separate task per surface, so the literal `AC-N (SURFACE)` string maps one-to-one to a task. See the ac-convention rule.

- [ ] **T1**: Write failing test named `AC-1 (CLI): <short>` in `<test-file>`
- [ ] **T2**: Write failing test named `AC-1 (HTTP): <short>` in `<test-file>` [P]
- [ ] **T3**: Implement `<src-file>` to pass T1 and T2
- [ ] **T4**: Write failing test for `AC-2`
- [ ] **T5**: Implement `<src-file>` to pass T4
- [ ] **T6** [P]: <…>
- [ ] **T-audit**: Run `/lcd:audit <slug>`; resulting `audit.md` has zero MISSING/BLOCKED rows
- [ ] **T-final**: Run the project's full test + lint + typecheck (detected toolchain), all green

## Checkpoint validation

After every block of related tasks, the suite must stay green. If T3 passes but T5's implementation breaks T1, stop and fix before moving on.

## Linkbacks

- `AC-1 (CLI)` → T1, T3
- `AC-1 (HTTP)` → T2, T3
- `AC-2` → T4, T5
- <…>

---

<!--
Quality checks before starting implementation:
  - Every AC × non-`none`-surface row in plan.md has at least one test task above
  - Every new file in plan.md "File structure" has at least one task that creates it
  - Tests appear before their implementation
  - T-audit appears before T-final (the audit gate must pass before suite-final)
  - T-final exists (run the suite, lint, type check)
-->
