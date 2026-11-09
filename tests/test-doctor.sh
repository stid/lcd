#!/usr/bin/env bash
# Tests for bin/lcd-doctor.sh — the conventions health check.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"

init_tmpdir
proj="$tmp/proj"
mkdir -p "$proj/.claude/rules" "$proj/docs/lcd"

write_conventions() {
  cat > "$proj/.claude/rules/lcd-conventions.md" <<EOF
<!-- lcd-conventions:v1 -->
artifact-root: ${1:-docs/lcd}
spec: ${1:-docs/lcd}/SPEC.md
living-spec: ${4:-off}
test-placement: tests/<slug>/<surface>.test.ts
test-discovery-glob: tests/**/*.test.ts
scoped-test: ${2:-vitest run {path}}
bail: ${3:-vitest run --bail 1 {path}}
single-test: vitest run -t '{name}'
gate: vitest run && npx tsc --noEmit
eval: n/a — deterministic project
maintenance-bundle: vitest run; npm outdated
<!-- /lcd-conventions -->
EOF
}

run_doctor() { bash "$PLUGIN_BIN/lcd-doctor.sh" "$proj" 2>&1; }

# --- not onboarded → FAIL -------------------------------------------------------
out="$(run_doctor)"; code=$?
assert_exit 1 "$code" "missing conventions fails"
assert_contains "$out" "not onboarded" "names the problem"

# --- healthy setup → exit 0 -----------------------------------------------------
write_conventions
touch "$proj/docs/lcd/MAP.md" "$proj/docs/lcd/DECISIONS.md"
printf '## LCD\nlcd:triage routes new work.\n' > "$proj/CLAUDE.md"
default_ac() {
  printf -- '---\npaths: ["docs/lcd/**/spec.md", "docs/lcd/**/JOURNAL.md"]\n---\n' > "$proj/.claude/rules/ac-convention.md"
}

# --- AC-3 (CLI): default root without the project ac-convention copy → WARN, not FAIL ---
# (plugins have no rules/ component, so only the project copy ever auto-loads)
out="$(run_doctor)"; code=$?
assert_exit 0 "$code" "AC-3 (CLI) missing default-root ac-convention does not fail"
assert_contains "$out" "WARN — ac-convention" "AC-3 (CLI) missing default-root ac-convention warns"

default_ac
out="$(run_doctor)"; code=$?
assert_exit 0 "$code" "healthy setup passes"
assert_contains "$out" "doctor: 0 FAIL, 0 WARN" "fully green"
assert_contains "$out" "OK   — ac-convention" "AC-3 (CLI) project ac-convention covering the root is OK"
# lowercase angle tokens (<slug>, <surface>) are substitution markers, NOT placeholders
assert_not_contains "$out" "placeholder" "substitution tokens not flagged"

# --- leftover placeholder → FAIL --------------------------------------------------
write_conventions docs/lcd "<SCOPED_CMD>"
out="$(run_doctor)"; code=$?
assert_exit 1 "$code" "placeholder key fails"
assert_contains "$out" "still a placeholder" "placeholder named"

# --- watch-mode command → FAIL ----------------------------------------------------
write_conventions docs/lcd "vitest {path}"
out="$(run_doctor)"; code=$?
assert_exit 1 "$code" "watch-mode vitest fails"
assert_contains "$out" "watch mode" "watch-mode reason given"

# --- non-default root without ac-convention override → FAIL ------------------------
write_conventions ".lcd"
mkdir -p "$proj/.lcd"
touch "$proj/.lcd/MAP.md" "$proj/.lcd/DECISIONS.md"
out="$(run_doctor)"; code=$?
assert_exit 1 "$code" "missing ac-convention override fails"
assert_contains "$out" "ac-convention" "override check named"

# --- …and passes once the override exists ------------------------------------------
printf -- '---\npaths: [".lcd/**/spec.md", ".lcd/**/JOURNAL.md"]\n---\n' \
  > "$proj/.claude/rules/ac-convention.md"
out="$(run_doctor)"; code=$?
assert_exit 0 "$code" "override satisfies the check"

# --- AC-3 (CLI): back on the default root, a copy that covers another root warns -------
write_conventions docs/lcd
out="$(run_doctor)"; code=$?
assert_exit 0 "$code" "AC-3 (CLI) wrong-root copy at default root does not fail"
assert_contains "$out" "WARN — ac-convention" "AC-3 (CLI) wrong-root copy at default root warns"

# --- AC-3 (CLI): coverage is judged on the paths: globs, not a substring anywhere ---------
# root `docs` is a substring of the stock docs/lcd globs (and `spec` of the body), but
# `docs/lcd/**` never matches docs/work/<slug>/spec.md
default_ac
printf '\nEvery spec in docs and lcd work dirs.\n' >> "$proj/.claude/rules/ac-convention.md"
for r in docs spec; do
  write_conventions "$r"
  mkdir -p "$proj/$r"; touch "$proj/$r/MAP.md" "$proj/$r/DECISIONS.md"
  out="$(run_doctor)"; code=$?
  assert_exit 1 "$code" "AC-3 (CLI) root '$r' not covered by docs/lcd globs fails"
done
default_ac

# --- living-spec: on but SPEC.md missing → WARN (not FAIL) --------------------------
write_conventions docs/lcd "vitest run {path}" "vitest run --bail 1 {path}" on
out="$(run_doctor)"; code=$?
assert_exit 0 "$code" "living-spec missing SPEC.md warns, does not fail"
assert_contains "$out" "living-spec: on but" "missing SPEC.md is named"

# --- …and OK once SPEC.md exists ---------------------------------------------------
touch "$proj/docs/lcd/SPEC.md"
out="$(run_doctor)"; code=$?
assert_exit 0 "$code" "living-spec on with SPEC.md passes"
assert_contains "$out" "SPEC.md exists" "SPEC.md presence acknowledged"

# --- a project with no test suite declares n/a → no WARN ---------------------------
# Docs-only projects fill the test keys with an explicit `n/a`; that is a filled-in
# answer, not a gap, so the placement-vs-glob heuristic must not warn about it.
cat > "$proj/.claude/rules/lcd-conventions.md" <<'EOF'
<!-- lcd-conventions:v1 -->
artifact-root: docs/lcd
spec: docs/lcd/SPEC.md
living-spec: on
test-placement: n/a — docs-only project, no test suite
test-discovery-glob: n/a — no tests in this project
scoped-test: n/a — docs-only project
bail: n/a — docs-only project
single-test: n/a — docs-only project
gate: n/a — docs-only project; prose review is the gate
eval: n/a — deterministic project
maintenance-bundle: n/a — nothing to build
<!-- /lcd-conventions -->
EOF
out="$(run_doctor)"; code=$?
assert_exit 0 "$code" "docs-only project passes"
assert_contains "$out" "doctor: 0 FAIL, 0 WARN" "n/a test keys produce no WARN"
assert_not_contains "$out" "may not match discovery glob" "placement heuristic skipped for n/a"

# --- AC-1 (CLI) / AC-2 (CLI): the pointer check follows what Claude Code loads ----------
# Claude Code (>= 2.1.277) reads AGENTS.md only when no CLAUDE.md exists, or when CLAUDE.md
# imports it with `@AGENTS.md`. A pointer that Claude never loads is not a pointer.
pointer='## LCD\nlcd:triage routes new work.\n'

rm -f "$proj/CLAUDE.md" "$proj/AGENTS.md"
out="$(run_doctor)"; code=$?
assert_contains "$out" "WARN — pointer" "AC-1 (CLI) no instruction file at all warns"

printf "$pointer" > "$proj/AGENTS.md"
out="$(run_doctor)"; code=$?
assert_contains "$out" "OK   — pointer" "AC-1 (CLI) AGENTS.md-only pointer is loaded by Claude"
assert_contains "$out" "doctor: 0 FAIL, 0 WARN" "AC-2 (CLI) AGENTS.md alone raises no shadowing warning"

printf '# Project\nBuild with make.\n' > "$proj/CLAUDE.md"
out="$(run_doctor)"; code=$?
assert_contains "$out" "WARN — pointer" "AC-1 (CLI) pointer only in a shadowed AGENTS.md warns"
assert_contains "$out" "WARN — AGENTS.md" "AC-2 (CLI) CLAUDE.md without the import shadows AGENTS.md"

printf '@AGENTS.md\n\n# Project\nBuild with make.\n' > "$proj/CLAUDE.md"
out="$(run_doctor)"; code=$?
assert_contains "$out" "OK   — pointer" "AC-1 (CLI) pointer reached through the @AGENTS.md import"
assert_not_contains "$out" "WARN — AGENTS.md" "AC-2 (CLI) importing CLAUDE.md does not shadow"

printf "$pointer" > "$proj/CLAUDE.md"
printf '# Shared rules\nUse tabs.\n' > "$proj/AGENTS.md"
out="$(run_doctor)"; code=$?
assert_contains "$out" "OK   — pointer" "AC-1 (CLI) pointer in CLAUDE.md is loaded"
assert_contains "$out" "WARN — AGENTS.md" "AC-2 (CLI) both files, no import, still warns"
rm -f "$proj/AGENTS.md"

exit 0
