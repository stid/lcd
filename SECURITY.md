# Security policy

## Supported versions

Only the latest release receives security fixes. Please upgrade before reporting.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting on this repository (Security tab → "Report a
vulnerability"). Please don't open a public issue for a suspected vulnerability, and don't send
reports by email.

## Scope

This plugin ships shell hook scripts that run inside your Claude Code sessions. Two properties are
part of the contract, and a break in either is worth reporting:

- Hooks are designed to fail open — a malfunction, missing dependency, or unparseable input must
  never block normal editing. A hook that blocks or mutates edits unexpectedly is a bug, and a
  security-relevant one.
- The deterministic CI (fixture tests, manifest checks, `claude plugin validate`) makes no model
  API calls.

Treat any hook behavior that blocks, deletes, or modifies files outside its stated purpose as
reportable under the process above.
