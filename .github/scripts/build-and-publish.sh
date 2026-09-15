#!/usr/bin/env bash
set -euo pipefail

NAMESPACE_LC=$(echo "$DOCKERHUB_USERNAME" | tr '[:upper:]' '[:lower:]')
IMAGE="docker.io/${NAMESPACE_LC}/wolfpack-python"
DATE_TAG=$(date -u +%Y%m%d)
TAR="image-${VERSION}.tar"

# Build locally instead of `apko publish` so Trivy can scan the tarball
# directly (--input) instead of pulling the image back from Docker Hub.
apko build \
  "images/python/${VERSION}/apko.yaml" \
  "${IMAGE}:${VERSION}" \
  "${TAR}" \
  --arch x86_64

# apko names the docker-loadable image after the arch (e.g. "...-amd64"),
# not the plain tag we asked for, so read back whatever it actually loaded.
LOADED_REF=$(docker load < "${TAR}" | sed -n 's/^Loaded image: //p')

docker tag "${LOADED_REF}" "${IMAGE}:${VERSION}"
docker tag "${LOADED_REF}" "${IMAGE}:${VERSION}-${DATE_TAG}"
docker push "${IMAGE}:${VERSION}"
docker push "${IMAGE}:${VERSION}-${DATE_TAG}"

# Docker records the registry digest locally once the push succeeds, so this
# needs no pull back from Docker Hub.
DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "${IMAGE}:${VERSION}-${DATE_TAG}")

echo "image=${IMAGE}:${VERSION}-${DATE_TAG}" >> "$GITHUB_OUTPUT"
echo "tar=${TAR}" >> "$GITHUB_OUTPUT"
echo "digest=${DIGEST}" >> "$GITHUB_OUTPUT"
