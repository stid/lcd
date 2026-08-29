#!/usr/bin/env bash
# run-eval.sh — prompt-eval benchmark runner (work-item: eval-harness).
#
# One invocation = one arm = one run: materialize a throwaway workspace from the frozen
# fixture, drive a single non-interactive Deep-lane run against the chosen plugin
# variant, grade it mechanically, append the row to the results table. A/B is
# composition: invoke N times alternating --arm/--plugin-dir; read evals/results.md.
#
# FAILS CLOSED (instrument, not guardrail): any missing precondition refuses with exit 2.
# The model call uses --dangerously-skip-permissions — acceptable only because the run
# is confined to a throwaway workspace (a fresh temp dir unless --workspace says otherwise).
#
# Runs cost real API tokens and are never triggered by CI on pull requests — see
# CONTRIBUTING for the evidence-in-PR policy (contributors run locally with their own key).
#
# Usage:
#   evals/run-eval.sh --arm <label> [--baseline] [--plugin-dir <plugin-root>]
#                     [--fixture evals/fixture] [--results evals/results.md]
#                     [--workspace <dir>] [--slug stats-surfaces] [--dry-run]
#
# --baseline: bare-agent arm (D-025 in the dev harness). No plugin loads; the workspace
# copy is stripped of the fixture's methodology onboarding (.claude/, docs/) and the strip
# is verified fail-closed; the frozen baseline prompt drives the run and the finish line
# is an EVAL-DONE marker instead of the audit artifact. Contradicts --plugin-dir.
#
# Isolation (BOTH arms, symmetric): every model call runs with CLAUDE_CONFIG_DIR pointed
# at a fresh empty dir (bypasses user-level plugins, settings and CLAUDE.md where the host
# supports it) and --settings carrying a plugin-disable map built from the operator's real
# settings (object map, explicit false per plugin — the schema-valid form; an empty array
# is inert). The arms differ by exactly one flag: the plugin arm adds --plugin-dir.
# Env:
#   EVAL_CLAUDE_BIN    model CLI (default: claude)
#   EVAL_CLAUDE_MODEL  model for the run (default: claude-fable-5 — the experiment's premise
#                      is Fable 5 behavior; pin explicitly, never trust the CLI default)
#   EVAL_CLAUDE_FLAGS  extra flags for the model call
#                      (default: --output-format json --dangerously-skip-permissions)
#   EVAL_MAX_LEGS      max model legs per run (default: 8). A single -p turn often ends
#                      after one pipeline phase; the runner re-invokes with --continue
#                      until the audit artifact exists or legs run out.

set -uo pipefail

plugin_root="$(cd "$(dirname "$0")/.." && pwd)"

arm=""
plugin_dir="$plugin_root"
plugin_dir_explicit=0
baseline=0
fixture="$plugin_root/evals/fixture"
results="$plugin_root/evals/results.md"
workspace=""
slug="stats-surfaces"
dry_run=0

usage() { echo "usage: $0 --arm <label> [--baseline] [--plugin-dir DIR] [--fixture DIR] [--results FILE] [--workspace DIR] [--slug SLUG] [--dry-run]" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arm)        arm="${2:-}"; shift 2 ;;
    --baseline)   baseline=1; shift ;;
    --plugin-dir) plugin_dir="${2:-}"; plugin_dir_explicit=1; shift 2 ;;
    --fixture)    fixture="${2:-}"; shift 2 ;;
    --results)    results="${2:-}"; shift 2 ;;
    --workspace)  workspace="${2:-}"; shift 2 ;;
    --slug)       slug="${2:-}"; shift 2 ;;
    --dry-run)    dry_run=1; shift ;;
    *) usage; exit 2 ;;
  esac
done

[[ -n "$arm" ]] || { usage; exit 2; }

claude_bin="${EVAL_CLAUDE_BIN:-claude}"
claude_model="${EVAL_CLAUDE_MODEL:-claude-fable-5}"
claude_flags="${EVAL_CLAUDE_FLAGS:---output-format json --dangerously-skip-permissions}"
max_legs="${EVAL_MAX_LEGS:-8}"
if [[ $baseline -eq 1 ]]; then
  prompt_file="$plugin_root/evals/feature-prompt-baseline.md"
else
  prompt_file="$plugin_root/evals/feature-prompt.md"
fi
[[ -n "$workspace" ]] || workspace="$(mktemp -d "${TMPDIR:-/tmp}/lcd-eval-XXXXXX")/$arm"
config_dir="$(dirname "$workspace")/claude-config-$arm"

# --- preflight: fail closed, naming the precondition -------------------------------
refuse() { echo "refused: $1" >&2; exit 2; }

# Plugin-disable map (0.17.1, evaluator finding): enabledPlugins takes an OBJECT map with
# an explicit false per plugin — an empty array is schema-invalid and silently inert, and
# --plugin-dir ADDS to the installed set rather than replacing it. Build the map from the
# operator's real settings so every user-enabled plugin is disabled for the run; fail
# closed if the file exists but can't be parsed (an instrument must not guess).
user_settings="${HOME}/.claude/settings.json"
if [[ -f "$user_settings" ]]; then
  command -v jq >/dev/null 2>&1 \
    || refuse "jq required to build the plugin-disable map from $user_settings"
  disable_map="$(jq -c '{enabledPlugins: ((.enabledPlugins // {}) | with_entries(.value = false))}' \
      "$user_settings" 2>/dev/null)" \
    || refuse "cannot parse $user_settings to build the plugin-disable map"
  [[ -n "$disable_map" ]] || refuse "cannot parse $user_settings to build the plugin-disable map"
else
  disable_map='{"enabledPlugins":{}}'
fi
isolation_flags=(--settings "$disable_map")

[[ $baseline -eq 1 && $plugin_dir_explicit -eq 1 ]] \
  && refuse "--baseline contradicts --plugin-dir (the baseline arm runs with no plugin)"
[[ -d "$fixture" && -f "$fixture/package.json" ]] \
  || refuse "fixture not found or not a project: $fixture"
[[ -f "$fixture/.claude/rules/lcd-conventions.md" ]] \
  || refuse "fixture is not LCD-onboarded: $fixture"
[[ $baseline -eq 0 && ! -f "$plugin_dir/.claude-plugin/plugin.json" ]] \
  && refuse "plugin variant not found: $plugin_dir (no .claude-plugin/plugin.json)"
[[ -f "$prompt_file" ]] || refuse "feature prompt missing: $prompt_file"
command -v "$claude_bin" >/dev/null 2>&1 \
  || refuse "model CLI not found: $claude_bin (set EVAL_CLAUDE_BIN)"
[[ -e "$workspace" ]] && refuse "workspace already exists: $workspace"

if [[ $dry_run -eq 1 ]]; then
  echo "DRY RUN — resolved plan (no model call, nothing materialized):"
  echo "  arm: $arm"
  echo "  fixture: $fixture"
  if [[ $baseline -eq 1 ]]; then
    echo "  plugin: none (baseline)"
  else
    echo "  plugin: $plugin_dir"
  fi
  echo "  slug: $slug"
  echo "  prompt: $prompt_file"
  echo "  workspace: $workspace"
  echo "  results: $results"
  echo "  isolation: CLAUDE_CONFIG_DIR=$config_dir · --settings $disable_map"
  echo "  model: $claude_bin --model $claude_model $claude_flags (max $max_legs legs)"
  exit 0
fi

# --- materialize the throwaway workspace -------------------------------------------
mkdir -p "$(dirname "$workspace")"
cp -R "$fixture" "$workspace"
if [[ $baseline -eq 1 ]]; then
  # Strip the methodology onboarding, then VERIFY the strip (AC-2: a run that cannot
  # guarantee absence must not start — a "baseline" with residue is silently wrong).
  rm -rf "$workspace/.claude" "$workspace/docs" 2>/dev/null
  [[ -e "$workspace/.claude" || -e "$workspace/docs" ]] \
    && refuse "baseline strip left methodology residue in $workspace"
fi
git -C "$workspace" init -q -b main
git -C "$workspace" add -A
git -C "$workspace" -c user.email=eval@local -c user.name=eval \
  -c commit.gpgsign=false commit -qm "baseline: frozen fixture"
git -C "$workspace" tag eval-baseline

# --- the run ------------------------------------------------------------------------
# A single -p turn tends to end after one pipeline phase, so drive legs until the
# audit artifact exists (the pipeline's own finish line) or legs run out. Leg 1 gets
# the frozen feature prompt; later legs --continue with a fixed nudge.
# IS_SANDBOX=1: permit --dangerously-skip-permissions under root in containerized
# environments — acceptable here because the run is confined to the throwaway workspace.
echo "running arm '$arm' in $workspace …" >&2
if [[ $baseline -eq 1 ]]; then
  finish_artifact="$workspace/EVAL-DONE"
  finish_label="EVAL-DONE marker"
  nudge="Continue building the 'stats' feature per the original instructions. Do not stop until the feature is complete with the full test suite green — then create a file named EVAL-DONE at the repository root as your final action. If hard-blocked, record why in BLOCKED.md and stop."
  plugin_args=()
else
  finish_artifact="$workspace/docs/lcd/work/$slug/audit.md"
  finish_label="audit artifact"
  nudge="Continue the LCD Deep-lane pipeline for '$slug' from wherever it stands (check docs/lcd/work/$slug/). Do not stop until the audit for $slug has run with all rows OK and the full test suite is green, or you are hard-blocked (record why in the JOURNAL)."
  plugin_args=(--plugin-dir "$plugin_dir")
fi
mkdir -p "$config_dir"
leg=0
while [[ ! -f "$finish_artifact" && $leg -lt $max_legs ]]; do
  leg=$((leg + 1))
  if [[ $leg -eq 1 ]]; then
    leg_args=(-p "$(cat "$prompt_file")")
  else
    leg_args=(-p --continue "$nudge")
  fi
  # shellcheck disable=SC2086
  (cd "$workspace" && IS_SANDBOX=1 CLAUDE_CONFIG_DIR="$config_dir" \
      "$claude_bin" "${leg_args[@]}" \
      --model "$claude_model" "${plugin_args[@]}" "${isolation_flags[@]}" $claude_flags \
      > "run-$leg.json" 2>> run.stderr)
  run_code=$?
  [[ $run_code -eq 0 ]] || echo "warning: leg $leg exited $run_code (continuing — the row is the verdict)" >&2
done
echo "run finished after $leg leg(s); $finish_label $( [[ -f "$finish_artifact" ]] && echo present || echo ABSENT )" >&2

# --- grade + append -----------------------------------------------------------------
grade_args=()
[[ $baseline -eq 1 ]] && grade_args=(--baseline)
row="$(bash "$plugin_root/evals/grade.sh" "${grade_args[@]}" "$workspace" "$slug" "$arm")" \
  || refuse "grading failed for $workspace"
# Stamp the model id on the row (here, not in the golden-locked grader): rows are
# comparable only within one model id — a silent model change must be visible per row.
row="$row · model: $claude_model"
[[ -f "$results" ]] || printf '# Eval results — one row per benchmark run (append-only)\n\n<!-- rows are comparable only within the same model id -->\n\n' > "$results"
printf '%s\n' "$row" >> "$results"
printf '%s\n' "$row"
