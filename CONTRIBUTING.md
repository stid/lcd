# Contributing to LCD

Thanks for your interest. LCD is a Claude Code plugin — a set of skills, commands, templates,
bundled rules, and the `bin/` scripts. There's no build step.

## Develop & test locally

Load the plugin from your checkout without a marketplace:

```bash
claude --plugin-dir /path/to/lcd
# inside the session, after editing files:
/reload-plugins
```

Validate the manifest and structure:

```bash
claude plugin validate /path/to/lcd
```

Run the fixture tests — every `bin/` script has them, they're plain bash and take seconds:

```bash
tests/run.sh            # whole suite
tests/run.sh doctor     # substring filter
```

CI runs the same suite plus manifest checks and `claude plugin validate` on every PR. It is
deterministic on purpose: no CI job calls a model API.

A good smoke test: point `--plugin-dir` at a throwaway project that has **none** of your global
rules, run `/lcd:onboard`, then a Quick-lane change and a small Deep-lane feature. This proves
LCD is self-contained (it leans only on its own bundled `rules/`, never your machine's config).

## Project conventions

- LCD is governed by its own bundled rules under `rules/` — notably `no-overengineering` and the
  three-lane discipline. Keep the common path light; weight is earned, never default.
- Skill/command names are **bare** folder/file names (e.g. `triage/`, `plan.md`); Claude Code
  namespaces them as `/lcd:<name>`.
- Reference bundled assets with `${CLAUDE_PLUGIN_ROOT}` — never hardcode absolute paths.
- The scripts live in `bin/` (on the Bash-tool PATH while the plugin is enabled); every one of
  them has a fixture test under `tests/`.

## Prompt changes and evals

The skills and commands are the product, so prose changes are regression-checked by the eval
harness in `evals/` (a frozen fixture project, a scripted Deep-lane run, a golden-locked
mechanical grader). Eval runs call a model and cost real tokens, which is why **CI never runs
them on pull requests**. The policy is evidence-in-PR:

- If your PR touches skill/command/rule prose, run the benchmark locally with your own API key
  (`evals/run-eval.sh --arm <your-branch>`, plus a baseline `--arm main` if none is recent) and
  paste the result rows into the PR description.
- Rows are comparable only within the same model id — the runner stamps it per row.
- Maintainers may re-run before merging; a `workflow_dispatch` eval workflow exists for that
  and is maintainer-only (it needs a repo secret that fork PRs never receive).

Mechanical changes (bin scripts, templates, docs, CI) need no eval evidence — the fixture
tests cover them.

## Pull requests

- Conventional commit prefixes (`feat:`, `fix:`, `docs:`, …).
- Update `CHANGELOG.md` under an `Unreleased` heading (create it if absent).
- Describe what changed and how you tested it (which `--plugin-dir` scenario, plus eval rows
  for prompt changes).
