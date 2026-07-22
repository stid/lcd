# Testing

- **Tests come first.** Write the failing test before the implementation; make it pass with the
  minimum code; refactor under green. The Deep lane's red-green loop automates this; Quick/Standard
  work follows it by hand.
- Test files live next to source or in the project's conventional location, using its framework's
  idiomatic structure and naming (e.g. `*.test.ts`, `test_*.py`, `*_test.go`, Rust `#[test]`).
- Reset shared state in setup/teardown hooks — never rely on test execution order.
- Run tests in the foreground; use non-watch runner forms so an automated loop never hangs.
- Prefer behavior coverage over line coverage; target meaningful coverage on new code.
- Run the **full** suite after dependency updates or multi-file changes before declaring done.
