---
name: onboard
description: Make a project Lean Context Development aware. Use when a project has no .claude/rules/lcd-conventions.md yet (first-time LCD setup), when the user says "set up LCD here" / "make this project LCD-aware" / runs /lcd:onboard, or to refresh a stale MAP or conventions block. Generates a MAP.md of the actual code organization, seeds DECISIONS.md, records test-discovery/runner conventions, asks once where LCD artifacts live, and appends a triage pointer to CLAUDE.md. Works on new and existing projects. Retrofit-safe.
user-invocable: true
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

# lcd:onboard (LCD Phase 0)

Make a project LCD-aware in one pass. LCD is otherwise zero-config — this skill records the few
facts the suite can't infer (where artifacts live, the test-discovery convention) and lays down the
durable spine (MAP, DECISIONS). A project that matches defaults still benefits from the MAP +
triage pointer. **Keep output minimal; retrofit-safe (skip-on-conflict).**


## Preconditions

1. Run `pwd`. If it is `$HOME`, refuse — this runs inside a target project, not your home dir.
2. Run `git rev-parse --is-inside-work-tree`. If not a git repo, ask whether to `git init` or abort.
3. If `.claude/rules/lcd-conventions.md` already exists, this is a **retrofit** — tell the user,
   re-detect, and update the machine block in place (preserve hand-edited prose and the existing
   `artifact-root`; don't re-ask the placement question). **Inject any keys the existing block is
   missing** — a project onboarded before a key existed (e.g. `spec` / `living-spec`, added in
   0.9.0) must gain it now, with existing values left untouched. This is the supported path for an
   existing project to adopt `living-spec`.

## Step 1 — analyze the repo (no writes yet)

- `git ls-files | head -50`, top-level directory scan, and lockfile detection.
- **Runtime / package manager** (priority): `bun.lockb`→Bun · `pnpm-lock.yaml`→pnpm · `yarn.lock`→Yarn ·
  `package-lock.json`/`package.json`→Node · `Cargo.toml`→Rust · `pyproject.toml`(`[tool.uv]`/`uv.lock`)→Python+uv ·
  `pyproject.toml`/`requirements.txt`→Python+pip · `go.mod`→Go · none→note it.
- **Notable existing choices** to seed DECISIONS: monorepo tool (turbo/nx/pnpm-workspace), state-mgmt
  or major framework lib (from deps), test framework, package manager.
- **Candidate artifact roots:** existing `docs/`, an ADR dir (`docs/adr/`, `docs/decisions/`),
  monorepo `packages/*`, else none.
- **Whether anything reviews the diff.** Scan the CI config (`.github/workflows/`, `.gitlab-ci.yml`,
  or the host's equivalent) for a job that *reads the changed code* — a reviewer action, a required
  human approval in branch protection — as opposed to jobs that only run tests and linters. Record
  yes/no; it is reported at the end, not asked about.

## Step 2 — ONE AskUserQuestion call (artifact placement + CI gate + living spec)

Use `AskUserQuestion` **once**, with up to three questions in the same call:

**Q1 (always): "Where should LCD artifacts (MAP, DECISIONS, work-items) live?"**
Options derived from Step 1, with the detected default first:
- `docs/lcd/` (recommended default)
- `docs/` (flat — if the project keeps docs there and you want them visible)
- match an existing ADR dir (e.g. `docs/adr/`) if one was found
- `.lcd/` (hidden, if the user prefers artifacts out of docs)

**Q2 (only if the repo is GitHub-hosted — `git remote get-url origin` contains `github.com`, or
`.github/` exists): "Install the CI audit gate (GitHub Actions workflow)?"**
- Yes (recommended for teams) — the Deep-lane audit then blocks PRs for *every* contributor,
  not just well-behaved agent sessions
- No — the audit stays a session-side gate

**Q3 (always): "Maintain a living current-state spec (`SPEC.md`), folded at closeout?"**
- No (default) — changes are tracked by the work-item chain + DECISIONS; the lighter setup.
- Yes (recommend only for a **mature/large** repo) — a living capability index of what the system
  does now; `lcd:reconcile` folds each closed Standard/Deep work-item into it at closeout, and
  triage reads the relevant section before scoping new work. Best once "what does this do now" is
  expensive to re-derive from the work-item chain. It can be enabled later by flipping
  `living-spec: on` and seeding `SPEC.md` — defaulting No costs nothing.

Everything else is inferred — do not ask more questions unless runtime detection came up empty.

## Step 3 — detect test-discovery convention (the crux)

Read the runner config to learn the discovery glob, then sample existing tests for actual placement:

| Runner | Read | Derive |
| ------ | ---- | ------ |
| Vitest | `vitest.config.*` / `vite.config.*` → `test.include`, `test.globals` | discovery glob; globals? |
| Jest | `jest.config.*` or `package.json#jest` → `testMatch` / `roots` | discovery glob |
| pytest | `pyproject.toml` `[tool.pytest.ini_options]` / `pytest.ini` → `testpaths`, `python_files` | roots + filename pattern |
| cargo | (convention) `tests/` + inline `#[cfg(test)]` | standard |
| go | (convention) `*_test.go` co-located | standard |

`Glob` for a couple of existing test files to confirm placement and suffix. Build the
**test-placement** template string. Derive **scoped-test / bail / single-test / gate** commands,
preferring the project's own `package.json` scripts where they map, and using **non-watch forms**
(`vitest run`, `jest --watchAll=false`, `pytest -x`) so the red-green loop never hangs. Set a
**maintenance-bundle** (e.g. `<gate>; <dep-audit>` — `npm outdated`, `cargo outdated`, etc., if available).
Determine **EVAL applicability**: grep for scorer/ranker/recommender/LLM-output paths; default `n/a — <reason>`.

**Monorepo:** when Step 1 detected a workspace (pnpm-workspace/turbo/nx/cargo workspace/go.work)
with heterogeneous runners, fill the bare keys from the dominant toolchain and add
`key[<path-prefix>]:` zone-scoped overrides for the exceptions (see
`${CLAUDE_PLUGIN_ROOT}/docs/monorepos.md`); seed one MAP Zone per package. Keep ONE artifact-root
at the workspace root — never per-package spines.

> **Runner caveats (verified — get the scoped command right or the red-green loop breaks):**
> - **node:test** (`node --test`): a bare *directory* argument errors ("Cannot find module"). Record
>   `scoped-test: node --test {path}/*.test.js` (a glob), and `single-test: node --test --test-name-pattern '{name}'`.
> - **vitest/jest**: bare `vitest`/`jest` watch by default — record the non-watch form (`vitest run`, `jest --watchAll=false`).
> - **pytest**: `pytest -x {path}` is fine. When unsure, prefer the name-filtered `single-test` form, which is path-robust.

## Step 4 — scaffold (retrofit-safe: skip + log any file that already exists)

Resolve `<root>` = the chosen artifact root. For each artifact, if it exists, **skip** and append
the path to `lcd:onboard-skipped.log`; otherwise write it. Never overwrite.

1. **`.claude/rules/lcd-conventions.md`** — from `${CLAUDE_PLUGIN_ROOT}/templates/lcd-conventions.md`. Fill the
   machine block: `artifact-root: <root>`, derived `map`/`decisions`/`spec`/`work-item-dir`, the
   detected test/gate/maintenance keys, and `living-spec: on|off` per Q3 (default `off`). Populate
   **Constitution notes** by scanning the project's
   `CLAUDE.md` + `.claude/rules/*` for must-restate constraints (no `any`, design tokens, version
   bump, dual-engine parity, etc.).
2. **`.claude/rules/ac-convention.md`** — **only when the chosen artifact root is NOT the default
   `docs/lcd`**: copy `${CLAUDE_PLUGIN_ROOT}/rules/ac-convention.md` and rewrite its `paths:`
   frontmatter to the chosen root (`["<root>/**/spec.md", "<root>/**/JOURNAL.md"]`), so the rule
   still auto-loads on specs/JOURNALs. The bundled rule's globs only cover the default root; without
   this override the convention never auto-loads on a custom root. Skip when root = `docs/lcd`.
3. **`<root>/MAP.md`** — from `${CLAUDE_PLUGIN_ROOT}/templates/MAP.md`, filled from the **actual** structure
   (Step 1): real top-level zones with their paths and responsibilities, real entry points, the
   surfaces actually exposed, and any invariants you can infer from CLAUDE.md/rules (e.g. the
   PR-comments-until-resolved rule, design-token rule). This must reflect reality, not a guess.
4. **`<root>/DECISIONS.md`** — from `${CLAUDE_PLUGIN_ROOT}/templates/DECISIONS.md`, seeded with one block per
   notable existing choice (Step 1), each marked "detected at onboarding — confirm/edit". Set the
   `Next id` comment past the seeded ids.
5. **`<root>/SPEC.md`** — **only when the user chose Yes at Q3** (`living-spec: on`): from
   `${CLAUDE_PLUGIN_ROOT}/templates/living-spec.md`, filling `<PROJECT_NAME>`.
   - **Greenfield (little/no shipped behaviour yet):** leave the surface sections empty — the first
     `lcd:reconcile` at a closeout fills them.
   - **Existing project — backfill once.** This is the analogue of how you just generated `MAP.md`
     from real structure: drive an AI pass from `MAP.md` (its Zones + "Surfaces in use") and confirm
     lightly against the actual surfaces (entry points, route table, tool/handler dirs, the EVAL
     harness). Write **one row per capability *group*, not per tool/endpoint** — a 20-tool MCP
     server or a 38-route API is one or a few grouped rows; enumerating every item turns SPEC into
     documentation and breaks MAP's "a map, not documentation / ~150 lines" discipline. Then seed
     **one anchor `D-NNN`** in DECISIONS ("adopt living-spec; backfill SPEC.md from current code")
     and cite it on every backfilled row as **`D-NNN (backfill)`**. Backfilled rows are a
     **lower-confidence tier** — code-derived, *not* AC-verified (no ACs, no cross-path audit); say
     so in the anchor decision and in a one-line banner at the top of SPEC.md. They **decay into
     rigor**: the next work-item that touches a capability supersedes its row with a real AC-pinned
     `D-NNN` (see `lcd:reconcile`).
   - Skip the file entirely when Q3 was No.
6. **CLAUDE.md pointer** — if `CLAUDE.md` exists and has no LCD pointer, append the ~12-line section
   (below). If `CLAUDE.md` doesn't exist, create a minimal one with just this section. Skip if a
   pointer is already present. **Also: if `AGENTS.md` exists** (the cross-tool standard for
   agent instructions — Linux Foundation-stewarded, read by most coding agents; Claude Code itself
   reads it when no CLAUDE.md is present), append the same pointer section there too (skip if
   present). The layering stance (D-017): **AGENTS.md carries the shared, tool-agnostic layer** —
   LCD's artifacts and lane discipline work even where the `lcd:*` commands aren't available —
   while **CLAUDE.md carries the Claude-specific layer**. Don't *create* an AGENTS.md (the project
   may not use other agents); mention in the completion message that creating one would extend the
   LCD pointer to them. **Keep the always-loaded layer small and hand-maintained:** these files are
   read every turn, and 2026 research on agent-instruction files finds hand-written ones help
   agents while bulk machine-generated ones can hurt outcomes and add cost — so append the ~12-line
   pointer and nothing more; never auto-generate prose into CLAUDE.md/AGENTS.md beyond it, and if
   the file is already long, say so rather than adding to the pile.
7. **`.claude/settings.json`** (the **committed, team-shared** file — the rest of the LCD spine is
   committed, so the permissions that make it run unattended should be too; a teammate cloning the
   repo then onboards for free) — merge-add (never clobber other keys; validate JSON parses) the
   scoped permissions below; skip each if present. Use `settings.local.json` instead **only if the
   user says they want them machine-local** — mention the choice in your completion message, don't
   ask another question. The scripts ship in the plugin's `bin/` (on the Bash-tool PATH while the
   plugin is enabled), so the permissions are **name-based** — no absolute or user-specific paths:
   - `Bash(audit-crosspath.sh:*)`
   - `Bash(parse-acs.sh:*)`
   - `Bash(lcd-doctor.sh:*)`

8. **CI audit gate (only if the user opted in at Step 2):**
   - Vendor the two audit scripts: copy `${CLAUDE_PLUGIN_ROOT}/bin/parse-acs.sh` and
     `${CLAUDE_PLUGIN_ROOT}/bin/audit-crosspath.sh` to `<root>/ci/` (keep them executable). CI
     can't assume the plugin is installed, so the repo carries its own copies; re-running
     `/lcd:onboard` refreshes them.
   - Write `.github/workflows/lcd-audit.yml` from `${CLAUDE_PLUGIN_ROOT}/templates/ci/lcd-audit.yml`,
     replacing every `<ARTIFACT_ROOT>` with the chosen root. Skip-on-conflict like everything else.

### The CLAUDE.md pointer (the project's only new always-loaded artifact)

```markdown
## Lean Context Development (LCD)
Non-trivial new work (new feature, ≥3 files, or any architecture change) → invoke
`lcd:triage`, which picks a lane (Quick / Standard / Deep) and states it in one line.
Trivial work (typo, one-liner, dep bump, known-cause fix) → go direct, no triage.
Artifacts live under `<root>/` (see `.claude/rules/lcd-conventions.md`).
Project map: `<root>/MAP.md` · Decisions: `<root>/DECISIONS.md`
Resume any work-item after a context reset: `/lcd:resume <slug>`.
```

## Git

Branch off the project's default branch (`git symbolic-ref refs/remotes/origin/HEAD`, else
`main`/`master`) unless already on a suitable feature branch. `git add` only what this skill
wrote/changed. Run `git status` and show it. **Do NOT push and do NOT open a PR.** Print the skip-log
if any artifact pre-existed.

## Quality gate before declaring done

Run `lcd-doctor.sh` (ships in the plugin's `bin/`) and show its output — it checks most of the
list below mechanically and must report **0 FAIL**. Then confirm:

- `.claude/rules/lcd-conventions.md` exists with a filled `<!-- lcd-conventions:v1 -->` block (no
  leftover `<PLACEHOLDER>` tokens), including `artifact-root`.
- `<root>/MAP.md` reflects the real structure (a reader could find any major area from it).
- `<root>/DECISIONS.md` exists (seeded or empty header).
- If `living-spec: on`, `<root>/SPEC.md` exists (from the living-spec template); if `off`, it is
  absent and that's correct.
- Non-default artifact root → `.claude/rules/ac-convention.md` exists with `paths:` globs matching
  that root (otherwise the AC convention never auto-loads).
- `settings.json` (or `settings.local.json` if the user chose machine-local) still parses as JSON.
- CLAUDE.md has exactly one LCD pointer; AGENTS.md (if the project has one) too.
- **If Step 1 found nothing that reviews the diff, say so once, in one line, and move on.** LCD's
  own gates do not read code: the `gate` command runs the suite, and the Deep-lane audit checks that
  every acceptance criterion has a test. Neither can see a defect in code no criterion describes, and
  that is where they are found — on a project that ran the full Deep lane, the audit passed and a
  code review of the same branch then found seven defects, two of them severe, all outside the ACs.
  So: "Nothing here reviews the diff — LCD's gates check tests and coverage, not code. Worth adding a
  review step on PRs." Do not scaffold one and do not ask a question about it; which reviewer, and
  whether it blocks, is the project's call and outside what this plugin ships.
- Tell the user the next step: start work normally — `lcd:triage` will auto-route — or run
  `/lcd:onboard` again later to refresh the MAP.
