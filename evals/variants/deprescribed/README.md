# Variant: deprescribed (Arm B of the de-prescription A/B)

Goal+constraints rewrites of the three Deep-lane phase commands (`specify.md`, `plan.md`,
`tasks.md`), per `docs/lcd/work/fable5-leverage/experiment-deprescription.md`:

- **Kept:** refusal gates, artifact-root resolution, the output-artifact contract (template +
  required fields), the AC format, JOURNAL sync, and "What NOT to do" phase boundaries.
- **Removed:** the numbered "What to do" step enumeration — replaced by a Goal paragraph plus a
  constraints list ("order your own steps; the gates and constraints are the contract").
- `test-gen` / `audit` / `redgreen-loop` are intentionally NOT in this variant (machine
  contracts — identical in both arms).

Build the loadable variant: `evals/make-variant.sh deprescribed /tmp/lcd-B`
Run Arm B: `evals/run-eval.sh --arm B --plugin-dir /tmp/lcd-B`
