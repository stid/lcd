# Quickstart — a worked walkthrough

This walks through onboarding a project and doing one Quick-lane change and one Deep-lane feature,
so you can see how LCD adapts process weight to the work.

## 0. Load the plugin

```bash
claude --plugin-dir /path/to/lcd
```

## 1. Onboard the project (once)

```
/lcd:onboard
```

Onboarding is a single interaction — up to three questions in one prompt: where LCD artifacts
should live (default `docs/lcd/`, the main question), whether to install the CI audit gate (only
asked on GitHub-hosted repos), and whether to maintain a living spec. LCD then writes:
- `docs/lcd/MAP.md` — a map of your project's real zones, surfaces, and invariants.
- `docs/lcd/DECISIONS.md` — seeded with notable existing choices it detected.
- `.claude/rules/lcd-conventions.md` — the few facts it can't infer (artifact root, test commands).
- a ~12-line LCD pointer appended to your `CLAUDE.md`.

## 2. A Quick-lane change

Just ask for the change normally. Triage scores it (e.g. *1 file, no new surface, trivially
reversible* → **Quick**) and states one line:

```
LCD → Quick (0 signals): no artifacts. Single-file tweak, reversible.
```

Then it implements directly, test-first where a test makes sense — no JOURNAL, no pipeline. If a
real decision gets made, one line is appended to `DECISIONS.md`. That's the whole point: the common
case carries no ceremony.

## 3. A Deep-lane feature

Ask for something larger — say a feature exposed on both a CLI and an HTTP route. Triage scores it
(*multiple files, 2 parallel surfaces* → **Deep**) and runs the pipeline:

```
/lcd:specify  add-export-api "Export records as CSV via CLI and HTTP"
/lcd:plan     add-export-api        # architecture, Constitution check (the plan vetted against the plugin's bundled rules — no-overengineering, no-downgrade, etc.), cross-path matrix
/lcd:tasks    add-export-api        # TDD-ordered task list, mirrored into the JOURNAL
/lcd:test-gen add-export-api        # one failing test per (AC × surface)
# lcd:redgreen-loop drives tests to green, one commit per red→green flip
/lcd:audit    add-export-api        # PR gate: every (AC × surface) has a handler AND a test
```

Each phase refuses if the previous artifact is missing — that gate is what keeps the orchestrator's
context small and the work resumable.

## 4. Resume after a context reset

```
/lcd:resume add-export-api
```

Rebuilds context from `MAP.md` + the JOURNAL's `lcd-resume:v1` block + DECISIONS headers — in about
2k tokens, no re-reading the whole feature.
