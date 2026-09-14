#!/usr/bin/env bash
set -euo pipefail

NAMESPACE_LC=$(echo "$DOCKERHUB_USERNAME" | tr '[:upper:]' '[:lower:]')
IMAGE="docker.io/${NAMESPACE_LC}/wolfpack-python"
DATE_TAG=$(date -u +%Y%m%d)

apko publish \
  "images/python/${VERSION}/apko.yaml" \
  "${IMAGE}:${VERSION}" \
  "${IMAGE}:${VERSION}-${DATE_TAG}" \
  --arch x86_64

echo "image=${IMAGE}:${VERSION}-${DATE_TAG}" >> "$GITHUB_OUTPUT"
