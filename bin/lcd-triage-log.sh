#!/usr/bin/env bash
# lcd-triage-log.sh — append a triage or closeout line to <artifact-root>/triage-log.md.
#
# The triage log is machine-read (`/lcd:tidy` summarizes the lane distribution and
# cross-reads triage lines against closeout lines), so the WRITE side is a script too:
# a format is only a contract if a program owns both ends. Creates the log with its
# header when missing; validates every field; echoes the appended line.
#
# Usage:
#   lcd-triage-log.sh triage   --root <artifact-root> --desc "<slug-or-short-desc>" \
#                              --signals <n> --lane <Quick|Standard|Deep> \
#                              --hard <yes|no> --risk <yes|no>
#   lcd-triage-log.sh closeout --root <artifact-root> --slug <slug> \
#                              --lane <Standard|Deep> --audit "<result>" \
#                              --reroutes <n> --interventions <n|n (note)> \
#                              [--iters <n|n/a[ (note)]>]
#
#   --audit accepts: "PASS (first run)" | "PASS (run <N>)" | "PASS (test-presence)"
#                  | "n/a" | "n/a (<note>)"
#   --iters is OPTIONAL (lean-loop): omitted → the line carries no "red-green iters"
#   field. Both shapes are valid — existing logs are never rewritten, and readers
#   (`/lcd:tidy`) accept lines with and without the iters field.
#
# Exit: 0 on append; 2 on usage/validation error (nothing written).

set -euo pipefail

usage_die() {
  echo "error: $1" >&2
  echo "usage: $0 triage|closeout --root <artifact-root> ... (see header)" >&2
  exit 2
}

[[ $# -ge 1 ]] || usage_die "missing subcommand"
sub="$1"; shift
[[ "$sub" == "triage" || "$sub" == "closeout" ]] || usage_die "unknown subcommand '$sub'"

root="" desc="" signals="" lane="" hard="" risk=""
slug="" audit="" reroutes="" iters="" interventions=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)          root="${2:-}"; shift 2 ;;
    --desc)          desc="${2:-}"; shift 2 ;;
    --signals)       signals="${2:-}"; shift 2 ;;
    --lane)          lane="${2:-}"; shift 2 ;;
    --hard)          hard="${2:-}"; shift 2 ;;
    --risk)          risk="${2:-}"; shift 2 ;;
    --slug)          slug="${2:-}"; shift 2 ;;
    --audit)         audit="${2:-}"; shift 2 ;;
    --reroutes)      reroutes="${2:-}"; shift 2 ;;
    --iters)         iters="${2:-}"; shift 2 ;;
    --interventions) interventions="${2:-}"; shift 2 ;;
    *) usage_die "unknown flag '$1'" ;;
  esac
done

[[ -n "$root" ]] || usage_die "--root is required"
[[ -d "$root" ]] || usage_die "artifact root not found: $root"

if [[ "$sub" == "triage" ]]; then
  [[ -n "$desc" ]] || usage_die "triage: --desc is required"
  [[ "$signals" =~ ^[0-9]+$ ]] || usage_die "triage: --signals must be an integer (got '$signals')"
  [[ "$lane" =~ ^(Quick|Standard|Deep)$ ]] || usage_die "triage: --lane must be Quick|Standard|Deep (got '$lane')"
  [[ "$hard" =~ ^(yes|no)$ ]] || usage_die "triage: --hard must be yes|no (got '$hard')"
  [[ "$risk" =~ ^(yes|no)$ ]] || usage_die "triage: --risk must be yes|no (got '$risk')"
  line="$(date +%F) · $desc · $signals signals · $lane · hard:$hard · risk:$risk"
else
  [[ -n "$slug" ]] || usage_die "closeout: --slug is required"
  [[ "$lane" =~ ^(Standard|Deep)$ ]] || usage_die "closeout: --lane must be Standard|Deep (got '$lane')"
  [[ "$audit" =~ ^(PASS\ \((first\ run|run\ [0-9]+|test-presence)\)|n/a( \(.+\))?)$ ]] \
    || usage_die "closeout: --audit must be 'PASS (first run)'|'PASS (run N)'|'PASS (test-presence)'|'n/a'|'n/a (<note>)' (got '$audit')"
  [[ "$reroutes" =~ ^[0-9]+$ ]] || usage_die "closeout: --reroutes must be an integer (got '$reroutes')"
  if [[ -n "$iters" ]]; then
    [[ "$iters" =~ ^([0-9]+|n/a( \(.+\))?)$ ]] || usage_die "closeout: --iters must be an integer or 'n/a[ (note)]' (got '$iters')"
  fi
  [[ "$interventions" =~ ^[0-9]+( \(.+\))?$ ]] || usage_die "closeout: --interventions must be an integer, optionally with a '(note)' (got '$interventions')"
  line="$(date +%F) · $slug · closeout · $lane · audit: $audit · re-routes: $reroutes"
  [[ -n "$iters" ]] && line="$line · red-green iters: $iters"
  line="$line · interventions: $interventions"
fi

log="$root/triage-log.md"
if [[ ! -f "$log" ]]; then
  printf '# LCD triage log\n\n<!-- date · work · n signals · lane · hard · risk -->\n\n' > "$log"
fi
printf '%s\n' "$line" >> "$log"
printf '%s\n' "$line"
