#!/usr/bin/env bash
set -euo pipefail

versions=$(find images/python -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
  | jq -R -s -c 'split("\n") | map(select(length > 0))')
echo "Found versions: $versions"
echo "versions=$versions" >> "$GITHUB_OUTPUT"
