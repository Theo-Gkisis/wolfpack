#!/usr/bin/env bash
set -euo pipefail

runtime_heading() {
  case "$1" in
    python) echo "Python" ;;
    node) echo "Node.js" ;;
    java) echo "Java" ;;
    *) echo "$1" ;;
  esac
}

{
  runtimes=$(ls scan-summaries/*.json | xargs -n1 basename | sed -E 's/^scan-summary-([a-z]+)-.*/\1/' | sort -u)
  for runtime in $runtimes; do
    echo "### $(runtime_heading "$runtime")"
    echo
    echo "| Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |"
    echo "|---|---|---|---|---|---|---|---|"
    for f in $(ls scan-summaries/scan-summary-${runtime}-*.json | sort -V); do
      jq -r '"| \(.version) | \(.critical) | \(.high) | \(.medium) | \(.low) | \(.unknown) | \(.critical+.high+.medium+.low+.unknown) | \(.scanned_at) |"' "$f"
    done
    echo
  done
} > table.md

awk '
  /<!-- TRIVY-TABLE:START -->/{print; while ((getline line < "table.md") > 0) print line; skip=1; next}
  /<!-- TRIVY-TABLE:END -->/{skip=0}
  !skip
' README.md > README.md.new
mv README.md.new README.md
