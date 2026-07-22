# Commits

- Conventional commit prefixes: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.
- Atomic commits — one logical change per commit. Include test updates in the same commit as the
  change they cover.
- In the Deep-lane red-green loop, commit **once per test that flips red→green**.
- Don't skip pre-commit hooks unless explicitly asked.
- Push only when the user asks. If on the default branch, branch first.
