#!/usr/bin/env bash
set -euo pipefail

counts=$(jq '[.Results[]?.Vulnerabilities[]?.Severity] | group_by(.) | map({(.[0]): length}) | add // {}' trivy-summary.json)

jq -n \
  --arg version "$VERSION" \
  --arg scanned_at "$(date -u +%Y-%m-%d)" \
  --argjson counts "$counts" \
  '{
    version: $version,
    scanned_at: $scanned_at,
    critical: ($counts["CRITICAL"] // 0),
    high: ($counts["HIGH"] // 0),
    medium: ($counts["MEDIUM"] // 0),
    low: ($counts["LOW"] // 0),
    unknown: ($counts["UNKNOWN"] // 0)
  }' > "scan-summary-${VERSION}.json"
