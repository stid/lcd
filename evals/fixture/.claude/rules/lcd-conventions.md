# LCD conventions for records-sandbox

> Per-project adapter for Lean Context Development. Pre-baked for the eval fixture so
> benchmark runs are deterministic — do NOT re-run `/onboard` here. The machine block
> below is read by the LCD suite; keep its keys intact.

**Generated:** 2026-06-11 (frozen fixture state)

## Machine block (read by the LCD suite — do not rename keys)

<!-- lcd-conventions:v1 -->
artifact-root: docs/lcd
map: docs/lcd/MAP.md
decisions: docs/lcd/DECISIONS.md
work-item-dir: docs/lcd/work/<slug>
test-placement: tests/<name>.test.js
test-discovery-glob: tests/*.test.js
scoped-test: node --test {path}
bail: node --test tests/
single-test: node --test --test-name-pattern {name} tests/
gate: node --test tests/
eval: n/a — deterministic node:test suite, no scored/LLM output
maintenance-bundle: node --test tests/
<!-- /lcd-conventions -->

Key notes: plain Node.js, zero external dependencies — the runner is the built-in
`node --test`; there is no separate bail flag, the suite is seconds-fast so bail = full run.
