# Spec: stats on both surfaces (golden fixture)

> Frozen golden-dataset spec — a canned *completed* run used to regression-lock the grader.
> Do not edit casually: tests/test-eval-grade.sh compares the grader's output on this
> workspace against evals/golden/expected-row.txt.

**Slug:** `stats-surfaces`
**Created:** 2026-06-11
**Status:** implemented

---

## Problem

The benchmark grader needs a frozen, known-good workspace to grade.

## User stories

- As the eval harness, I want a canned completed run, so that the grader is regression-locked.

## Acceptance criteria

**AC-1** (surfaces: CLI): Given records exist, when the stats command runs, then it reports count, last-updated, and checksum.

**AC-2** (surfaces: HTTP): Given records exist, when the stats endpoint is requested, then it reports count, last-updated, and checksum with semantics identical to the CLI.

## Out of scope

- Everything — this is a frozen fixture.
