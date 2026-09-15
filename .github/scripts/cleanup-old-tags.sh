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

# Page through every tag in the repo once, keeping name + digest (needed to
# find each tag's cosign ".sig" tag, which is named after the digest).
all_tags="[]"
url="https://hub.docker.com/v2/repositories/${NAMESPACE_LC}/${REPO}/tags/?page_size=100"
while [ "$url" != "null" ] && [ -n "$url" ]; do
  resp=$(curl -s -H "Authorization: JWT ${TOKEN}" "$url")
  page_entries=$(echo "$resp" | jq -c '[.results[] | {name, digest}]')
  all_tags=$(jq -c -n --argjson a "$all_tags" --argjson b "$page_entries" '$a + $b')
  url=$(echo "$resp" | jq -r '.next')
done

delete_tag() {
  local tag="$1"
  echo "Deleting ${NAMESPACE_LC}/${REPO}:${tag}"
  status=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
    -H "Authorization: JWT ${TOKEN}" \
    "https://hub.docker.com/v2/repositories/${NAMESPACE_LC}/${REPO}/tags/${tag}/")
  echo "  -> HTTP $status"
}

echo "$VERSIONS" | jq -r '.[]' | while read -r v; do
  to_delete=$(echo "$all_tags" | jq -r --arg v "$v" --argjson keep "$KEEP" '
    map(select(.name | test("^" + $v + "-[0-9]{8}$"))) | sort_by(.name) | reverse | .[$keep:] | .[].name
  ')
  for tag in $to_delete; do
    delete_tag "$tag"

    digest=$(echo "$all_tags" | jq -r --arg t "$tag" 'map(select(.name == $t)) | .[0].digest // empty')
    if [ -n "$digest" ]; then
      sig_tag="${digest/sha256:/sha256-}.sig"
      sig_exists=$(echo "$all_tags" | jq -r --arg s "$sig_tag" 'any(.name == $s)')
      # Only delete the signature if no other tag still points at this digest.
      shared_count=$(echo "$all_tags" | jq -r --arg d "$digest" --arg t "$tag" '[.[] | select(.digest == $d and .name != $t)] | length')
      if [ "$sig_exists" = "true" ] && [ "$shared_count" -eq 0 ]; then
        delete_tag "$sig_tag"
      fi
    fi
  done
done
