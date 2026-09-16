#!/usr/bin/env bash
set -euo pipefail

NAMESPACE_LC=$(echo "$DOCKERHUB_USERNAME" | tr '[:upper:]' '[:lower:]')
IMAGE="docker.io/${NAMESPACE_LC}/wolfpack-${RUNTIME}"
TAR="image-${RUNTIME}-${VERSION}.tar"

# Build locally instead of `apko publish` so Trivy can scan the tarball
# directly (--input) instead of pulling the image back from Docker Hub.
apko build \
  "images/${RUNTIME}/${VERSION}/apko.yaml" \
  "${IMAGE}:${VERSION}" \
  "${TAR}" \
  --arch x86_64

# apko names the docker-loadable image after the arch (e.g. "...-amd64"),
# not the plain tag we asked for, so read back whatever it actually loaded.
LOADED_REF=$(docker load < "${TAR}" | sed -n 's/^Loaded image: //p')

docker tag "${LOADED_REF}" "${IMAGE}:${VERSION}"
docker push "${IMAGE}:${VERSION}"

# apko already generates an SPDX SBOM as a side effect of the build above;
# just give it a name that's unique across the whole matrix.
SBOM="sbom-${RUNTIME}-${VERSION}.spdx.json"
mv sbom-x86_64.spdx.json "${SBOM}"

echo "tar=${TAR}" >> "$GITHUB_OUTPUT"
echo "sbom=${SBOM}" >> "$GITHUB_OUTPUT"
