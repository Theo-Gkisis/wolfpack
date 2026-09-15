#!/usr/bin/env bash
set -euo pipefail

NAMESPACE_LC=$(echo "$DOCKERHUB_USERNAME" | tr '[:upper:]' '[:lower:]')
IMAGE="docker.io/${NAMESPACE_LC}/wolfpack-python"
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
docker push "${IMAGE}:${VERSION}"

echo "tar=${TAR}" >> "$GITHUB_OUTPUT"
