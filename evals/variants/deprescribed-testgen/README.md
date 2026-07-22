# Variant: deprescribed-testgen (arm C — the D-009 follow-up)

Goal+constraints rewrite of `test-gen.md` only, overlaid on the shipped plugin (which already
carries the adopted de-prescribed `specify`/`plan`/`tasks` — D-009). Control arm = the shipped
plugin = the original experiment's Arm B rows in `evals/results.md`.

- **Kept verbatim:** the literal `AC-N (SURFACE)` contract + per-framework idioms (the machine
  contract `/lcd:audit` greps for), the spec/plan/tasks refusal gate, the `parse-acs.sh`
  malformed-spec refusal, framework detection + placement overrides, tests-must-fail + red
  confirmation, "What NOT to do", and the quality gate.
- **Removed:** the numbered "What to do" enumeration — replaced by Goal + Gates + Constraints.
- **Failure signature to watch:** `MISSING-TEST` audit rows (the literal contract slipping).

Build: `evals/make-variant.sh deprescribed-testgen /tmp/lcd-C`
Run:   `evals/run-eval.sh --arm C --plugin-dir /tmp/lcd-C`
