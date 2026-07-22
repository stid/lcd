# Plan: stats on both surfaces (golden fixture)

> Frozen golden-dataset plan — see spec.md header. The matrix below is what
> audit-crosspath.sh resolves when the grader runs on this workspace.

**Slug:** `stats-surfaces`
**Status:** implemented

---

## Goal

Provide the audit-complete matrix for the canned completed run.

## Cross-path behavior matrix

| AC | Surface | Path |
|---|---|---|
| `AC-1` | CLI | `cli.js:stats` |
| `AC-2` | HTTP | `server.js:/stats` |
