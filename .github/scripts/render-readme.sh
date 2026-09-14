#!/usr/bin/env bash
set -euo pipefail

{
  echo "| Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |"
  echo "|---|---|---|---|---|---|---|---|"
  for f in $(ls scan-summaries/*.json | sort -V); do
    jq -r '"| \(.version) | \(.critical) | \(.high) | \(.medium) | \(.low) | \(.unknown) | \(.critical+.high+.medium+.low+.unknown) | \(.scanned_at) |"' "$f"
  done
} > table.md

awk '
  /<!-- TRIVY-TABLE:START -->/{print; while ((getline line < "table.md") > 0) print line; skip=1; next}
  /<!-- TRIVY-TABLE:END -->/{skip=0}
  !skip
' README.md > README.md.new
mv README.md.new README.md
