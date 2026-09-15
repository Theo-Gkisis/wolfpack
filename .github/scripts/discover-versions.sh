#!/usr/bin/env bash
set -euo pipefail

# Each entry is a {runtime, version} pair, e.g. images/node/20 -> {"runtime":"node","version":"20"}
entries=$(find images -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | jq -R -s -c 'split("\n") | map(select(length > 0)) | map(split("/") | {runtime: .[0], version: .[1]})')
echo "Found entries: $entries"
echo "entries=$entries" >> "$GITHUB_OUTPUT"
