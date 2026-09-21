# wolfpack

[![build-images](https://github.com/Theo-Gkisis/wolfpack/actions/workflows/build-images.yml/badge.svg)](https://github.com/Theo-Gkisis/wolfpack/actions/workflows/build-images.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Hardened, minimal container base images for Python, Node.js, Java, and .NET — no shell, no package manager, nothing left for an attacker to reach for once they're inside.

## Overview

WolfPack is a self-hosted build pipeline that produces hardened container base images for four language runtimes, built on [Wolfi](https://github.com/wolfi-dev) with [apko](https://github.com/chainguard-dev/apko) instead of relying on a third party's pre-built images. It currently maintains **22 image variants** across 11 versions.

Every image is built the same way regardless of language: take Wolfi's minimal runtime package (and only that), add CA certificates, run as a non-root user, and ship it with no shell and no package manager. A matching `-dev` variant adds exactly what's needed to build software — the language's package manager or SDK, plus a minimal shell — and nothing else.

Nothing here is hand-built. One GitHub Actions pipeline rebuilds every image from scratch **every day**, so upstream security patches land automatically — no one has to file a "please bump the base image" ticket. Each build is scanned with [Trivy](https://github.com/aquasecurity/trivy), ships with an auto-generated SBOM, and updates this page's tables — see the links at the bottom of this page.

## Why this exists

Chainguard/Wolfi already publish hardened images for free — but the free tier only exposes a rolling `:latest`-style tag, with no way to pin a specific historical build. Self-hosting the build means keeping that control without paying for it, and having full visibility into exactly what's inside every image.

## Design principles

- **Hardened by default, usable by design.** Production images can't run a package manager or a shell — there's nothing for an attacker to reach for after landing inside one. The `-dev` variant exists purely so a multi-stage Dockerfile has somewhere to compile or install dependencies before copying the result into the hardened image.
- **One runtime, one registry namespace.** Python, Node.js, Java, and .NET each publish to their own Docker Hub repository (`wolfpack-python`, `wolfpack-node`, ...), so a tag never has to encode which language it belongs to.
- **No signing, no tag retention.** Both were built and then removed: image signing added real complexity for a security guarantee this project's size didn't need, and automated tag cleanup required holding a delete-scoped Docker Hub token, which is more standing risk than the tag clutter it solved. Every image now publishes under a single floating tag per version, overwritten daily.
- **Automate what a human would forget.** Rebuilding for security patches, scanning every image, generating SBOMs, and keeping this README's tables in sync are all handled by the same daily pipeline run — none of it depends on someone remembering to do it.

## Images

| Runtime | Docker Hub | Versions |
|---|---|---|
| Python | [Docker Hub](https://hub.docker.com/r/teogisis/wolfpack-python) | 3.10, 3.11, 3.12, 3.13, 3.14 |
| Node.js | [Docker Hub](https://hub.docker.com/r/teogisis/wolfpack-node) | 20, 22 |
| Java | [Docker Hub](https://hub.docker.com/r/teogisis/wolfpack-java) | 17, 21 |
| .NET | [Docker Hub](https://hub.docker.com/r/teogisis/wolfpack-dotnet) | 8, 10 |

Each version has two tags:

| Tag | Contains | Use for |
|---|---|---|
| `<version>` | Runtime + CA certs only. No shell, no package manager. | Production |
| `<version>-dev` | Same, plus the language's package manager/SDK (`pip` / `npm` / `maven` / `dotnet`) and a shell (`busybox`). | Builder stage |

Tags are overwritten with the newest build every day — there is no `latest` tag, so pick a version explicitly.

## Usage

Since production images have no shell or package manager, install dependencies in a `-dev` builder stage and copy them into the hardened final image. The same pattern applies to every runtime — only the package manager and entrypoint change.

```dockerfile
FROM teogisis/wolfpack-python:3.13-dev AS builder
WORKDIR /app
COPY requirements.txt .
RUN python3.13 -m pip install --no-cache-dir --target=/app/deps -r requirements.txt

FROM teogisis/wolfpack-python:3.13
WORKDIR /app
COPY --from=builder /app/deps /app/deps
COPY app.py .
ENV PYTHONPATH=/app/deps
ENTRYPOINT ["/usr/bin/python3.13", "/app/app.py"]
```

Both variants run as a non-root user (uid/gid `65532`) by default.

## How images are built

Everything lives in this repo and runs on a schedule — nothing is built by hand:

1. **Discover** ([source](.github/scripts/discover-versions.sh)) scans `images/<runtime>/<version>/` and turns every folder it finds into a build target — adding a runtime or version is just adding a folder, no pipeline changes needed.
2. **Build, scan, and publish** ([source](.github/scripts/build-and-publish.sh)) runs once per target, in parallel: apko builds the image from its `apko.yaml`, [Trivy](https://github.com/aquasecurity/trivy) scans it for CVEs, and the image is pushed to Docker Hub.
3. **Publish SBOMs** collects the SPDX SBOM apko generates for every image and deploys them as a static site via GitHub Pages.
4. **Update this README** collects every scan result and rewrites the tables below.

Source files:

- [Image configs](images) — the apko config for each image
- [Workflow file](.github/workflows/build-images.yml) — the daily pipeline
- [Scripts folder](.github/scripts) — the pipeline logic, one script per step

## Need a package that isn't in an image?

These images ship no package manager on purpose, so you can't `apk add` anything into a running container. If you need an extra OS-level package (e.g. `tzdata`, `tini`) that isn't already included:

1. Fork this repo.
2. Add the package to the relevant `images/<runtime>/<version>/apko.yaml` (and its `-dev` counterpart if needed), under `contents.packages`.
3. Build it yourself with [apko](https://github.com/chainguard-dev/apko):
   ```sh
   apko build images/<runtime>/<version>/apko.yaml <your-tag> output.tar --arch x86_64
   docker load < output.tar
   ```

This isn't something you can request through this repo's CI — it only builds and publishes the versions already committed here. Opening a PR is welcome if you think the package belongs in the image for everyone.

## Software Bill of Materials (SBOM)

Every image ships with an auto-generated SPDX SBOM, regenerated daily and published **[here](https://theo-gkisis.github.io/wolfpack/)**.

## Vulnerability scan results

Updated automatically by the daily build pipeline ([Trivy](https://github.com/aquasecurity/trivy)), broken down by runtime.

<!-- TRIVY-TABLE:START -->
### dotnet

| Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |
|---|---|---|---|---|---|---|---|
| 8 | 2 | 6 | 2 | 0 | 0 | 10 | 2026-09-21 |
| 8-dev | 7 | 21 | 7 | 0 | 0 | 35 | 2026-09-21 |
| 10 | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 10-dev | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |

### Java

| Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |
|---|---|---|---|---|---|---|---|
| 17 | 0 | 2 | 5 | 1 | 0 | 8 | 2026-09-21 |
| 17-dev | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 21 | 0 | 7 | 15 | 4 | 0 | 26 | 2026-09-21 |
| 21-dev | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |

### Node.js

| Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |
|---|---|---|---|---|---|---|---|
| 20 | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 20-dev | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 22 | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 22-dev | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |

### Python

| Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |
|---|---|---|---|---|---|---|---|
| 3.10 | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 3.10-dev | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 3.11 | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 3.11-dev | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 3.12 | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 3.12-dev | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 3.13 | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 3.13-dev | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 3.14 | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |
| 3.14-dev | 0 | 0 | 0 | 0 | 0 | 0 | 2026-09-21 |

<!-- TRIVY-TABLE:END -->

## License

[MIT](LICENSE)
