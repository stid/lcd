#!/usr/bin/env bash
# make-variant.sh — materialize an A/B plugin variant (work-item: deprescription-ab).
#
# Copies the shipped plugin and overlays a variant's command files, producing a loadable
# --plugin-dir for evals/run-eval.sh. Fails closed.
#
# Usage: evals/make-variant.sh <variant-name> <out-dir>
#   e.g. evals/make-variant.sh deprescribed /tmp/lcd-B

set -euo pipefail

plugin_root="$(cd "$(dirname "$0")/.." && pwd)"

[[ $# -eq 2 ]] || { echo "usage: $0 <variant-name> <out-dir>" >&2; exit 2; }
variant_dir="$plugin_root/evals/variants/$1"
out="$2"

[[ -d "$variant_dir/commands" ]] || { echo "refused: no such variant: $variant_dir" >&2; exit 2; }
[[ -e "$out" ]] && { echo "refused: out-dir already exists: $out" >&2; exit 2; }

cp -R "$plugin_root" "$out"
cp "$variant_dir/commands/"*.md "$out/commands/"
echo "variant '$1' materialized at $out (overlaid: $(ls "$variant_dir/commands" | tr '\n' ' '))"
