#!/usr/bin/env bash
set -euo pipefail

NAMESPACE_LC=$(echo "$DOCKERHUB_USERNAME" | tr '[:upper:]' '[:lower:]')
REPO="wolfpack-python"

TOKEN=$(curl -s -H "Content-Type: application/json" -X POST \
  -d "{\"username\": \"${DOCKERHUB_USERNAME}\", \"password\": \"${DOCKERHUB_TOKEN}\"}" \
  https://hub.docker.com/v2/users/login/ | jq -r .token)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "::error::Could not authenticate to the Docker Hub API"
  exit 1
fi

# Page through every tag in the repo once.
all_tags="[]"
url="https://hub.docker.com/v2/repositories/${NAMESPACE_LC}/${REPO}/tags/?page_size=100"
while [ "$url" != "null" ] && [ -n "$url" ]; do
  resp=$(curl -s -H "Authorization: JWT ${TOKEN}" "$url")
  page_names=$(echo "$resp" | jq -c '[.results[].name]')
  all_tags=$(jq -c -n --argjson a "$all_tags" --argjson b "$page_names" '$a + $b')
  url=$(echo "$resp" | jq -r '.next')
done

echo "$VERSIONS" | jq -r '.[]' | while read -r v; do
  to_delete=$(echo "$all_tags" | jq -r --arg v "$v" --argjson keep "$KEEP" '
    map(select(test("^" + $v + "-[0-9]{8}$"))) | sort | reverse | .[$keep:] | .[]
  ')
  for tag in $to_delete; do
    echo "Deleting ${NAMESPACE_LC}/${REPO}:${tag}"
    status=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
      -H "Authorization: JWT ${TOKEN}" \
      "https://hub.docker.com/v2/repositories/${NAMESPACE_LC}/${REPO}/tags/${tag}/")
    echo "  -> HTTP $status"
  done
done
