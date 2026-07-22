# LCD in a monorepo

LCD's spine is workspace-global; only the *toolchain keys* vary per package. The pattern:

## One spine, at the workspace root

- **One `artifact-root`** (default `docs/lcd/`) at the repo root — work-items, DECISIONS and the
  triage log are workspace concerns, not per-package ones. A feature spanning two packages is one
  work-item, not two.
- **`MAP.md` Zones = the packages.** One row per package (`packages/api`, `packages/web`, …) with
  its responsibility and "don't put here" guardrail; plus rows for shared infra (`tooling/`,
  `.github/`). The cross-package invariants ("api never imports from web") live in Invariants —
  exactly the sprawl rules a monorepo needs written down once.
- **One `DECISIONS.md`.** Monorepo decisions (workspace tool, shared tsconfig, versioning scheme)
  are precisely the kind that every future session must not relitigate.

## Per-package toolchains: zone-scoped keys

Where packages differ (runner, placement, filters), the `lcd-conventions.md` machine block carries
**zone-scoped overrides** — `key[<path-prefix>]:` — over the bare fallback keys:

```
artifact-root: docs/lcd
scoped-test: pnpm vitest run {path}
bail: pnpm vitest run --bail 1 {path}
gate: pnpm -r test && pnpm -r lint

scoped-test[packages/api]: pnpm --filter @acme/api exec vitest run {path}
bail[packages/api]: pnpm --filter @acme/api exec vitest run --bail 1 {path}
test-placement[packages/api]: packages/api/tests/<slug>/<surface>.test.ts

scoped-test[services/worker]: go -C services/worker test ./...
bail[services/worker]: go -C services/worker test -failfast ./...
test-placement[services/worker]: services/worker/<pkg>/<slug>_<surface>_test.go
```

Resolution rule (applied by the red-green loop and `/lcd:test-gen`): take the path you're
operating on (a boundary file, a test target), pick the scoped key with the **longest matching
path prefix**, fall back to the bare key. A work-item whose EDIT BOUNDARY spans zones with
different runners runs each zone's command for its own paths; the `gate` stays the workspace-wide
command (that's the integration check).

## Onboarding a monorepo

`/lcd:onboard` detects the workspace tool (pnpm-workspace/turbo/nx/cargo workspace/go.work)
in Step 1. When packages have heterogeneous runners, fill the machine block with the bare keys
for the dominant toolchain plus `key[<prefix>]:` overrides for the exceptions — and seed a MAP
Zone per package. `lcd-doctor.sh` validates the bare keys; scoped keys follow the same non-watch
rules (a watching `vitest` hangs the loop regardless of which package it sits in).

## What NOT to do

- Don't create a per-package artifact-root. Two spines = two places to look on a cold start.
- Don't put the package name in work-item slugs reflexively (`api-export-csv`) — slugs name the
  *work*; the EDIT BOUNDARY already says where it lands.
