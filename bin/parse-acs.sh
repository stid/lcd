#!/usr/bin/env bash
# parse-acs.sh — extract AC declarations from a <work-item>/spec.md file.
#
# Format expected (see the ac-convention rule):
#   **AC-<N>** (surfaces: <CSV>): <body>
#
# Surface tokens (fixed vocabulary): CLI, HTTP, MCP, RENDER, DB, EVAL, none
# A project uses whatever subset applies; the validator only rejects typos.
#
# Usage:   parse-acs.sh <path-to-spec.md>
# Output:  one tab-separated row per AC: <id>\t<surfaces-csv>\t<body>
# Exit:    0 if at least one AC parsed; 1 if file missing or malformed AC found.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <path-to-spec.md>" >&2
  exit 2
fi

spec="$1"
if [[ ! -f "$spec" ]]; then
  echo "error: spec not found: $spec" >&2
  exit 1
fi

# Surface CSV tokens validated against the fixed vocabulary.
allowed='^(CLI|HTTP|MCP|RENDER|DB|EVAL|none)$'
parsed=0
malformed=0

while IFS= read -r line; do
  if [[ "$line" =~ ^\*\*AC-([0-9]+)\*\*[[:space:]]+\(surfaces:[[:space:]]*([^\)]+)\):[[:space:]]*(.*)$ ]]; then
    id="AC-${BASH_REMATCH[1]}"
    surfaces_raw="${BASH_REMATCH[2]}"
    body="${BASH_REMATCH[3]}"
    # Normalize surface CSV: strip spaces, validate each token.
    csv=""
    has_none=0
    has_other=0
    IFS=',' read -ra toks <<< "$surfaces_raw"
    for tok in "${toks[@]}"; do
      t="$(echo "$tok" | tr -d '[:space:]')"
      if [[ ! "$t" =~ $allowed ]]; then
        echo "error: $spec: $id has invalid surface token '$t'" >&2
        malformed=1
        continue
      fi
      [[ "$t" == "none" ]] && has_none=1 || has_other=1
      csv+="${csv:+,}$t"
    done
    if [[ $has_none -eq 1 && $has_other -eq 1 ]]; then
      echo "error: $spec: $id mixes 'none' with other surface tokens" >&2
      malformed=1
    fi
    printf '%s\t%s\t%s\n' "$id" "$csv" "$body"
    parsed=$((parsed+1))
  elif [[ "$line" =~ ^\*\*AC- ]]; then
    echo "error: $spec: malformed AC line: $line" >&2
    malformed=1
  fi
done < "$spec"

if [[ $malformed -eq 1 ]]; then
  exit 1
fi
if [[ $parsed -eq 0 ]]; then
  echo "error: $spec: no AC declarations found (expected '**AC-N** (surfaces: ...)')" >&2
  exit 1
fi
