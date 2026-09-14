#!/usr/bin/env bash
set -euo pipefail

curl -sL "https://github.com/chainguard-dev/apko/releases/download/v${APKO_VERSION}/apko_${APKO_VERSION}_linux_amd64.tar.gz" -o apko.tar.gz
tar -xzf apko.tar.gz
sudo mv "apko_${APKO_VERSION}_linux_amd64/apko" /usr/local/bin/apko
apko version
