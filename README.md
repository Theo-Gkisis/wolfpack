# wolfpack

[![build-images](https://github.com/Theo-Gkisis/wolfpack/actions/workflows/build-images.yml/badge.svg)](https://github.com/Theo-Gkisis/wolfpack/actions/workflows/build-images.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Hardened, minimal container base images for Python, Node.js, Java, and .NET — built on [Wolfi](https://github.com/wolfi-dev) with [apko](https://github.com/chainguard-dev/apko). No distro, no shell, no package manager in production, and nothing an attacker could use to pivot after landing inside a container.

Rebuilt **every day** so upstream security patches land automatically, without anyone filing a "please bump the base image" ticket. Every build is scanned with [Trivy](https://github.com/aquasecurity/trivy) and ships with an auto-generated SBOM — see the links at the bottom of this page.

## Why this exists

Chainguard/Wolfi already publish hardened images for free — but the free tier only exposes a rolling `:latest`-style tag, with no way to pin a specific historical build. Self-hosting the build means keeping that control without paying for it, and having full visibility into exactly what's inside every image.

## Images

| Runtime | Docker Hub repo | Versions |
|---|---|---|
| Python | [`teogisis/wolfpack-python`](https://hub.docker.com/r/teogisis/wolfpack-python) | 3.10, 3.11, 3.12, 3.13, 3.14 |
| Node.js | [`teogisis/wolfpack-node`](https://hub.docker.com/r/teogisis/wolfpack-node) | 20, 22 |
| Java | [`teogisis/wolfpack-java`](https://hub.docker.com/r/teogisis/wolfpack-java) | 17, 21 |
| .NET | [`teogisis/wolfpack-dotnet`](https://hub.docker.com/r/teogisis/wolfpack-dotnet) | 8, 10 |

Each version has two tags:

| Tag | Contains | Use for |
|---|---|---|
| `<version>` | Runtime + CA certs only. No shell, no package manager. | Production |
| `<version>-dev` | Same, plus the language's package manager/SDK (`pip` / `npm` / `maven` / `dotnet`) and a shell (`busybox`). | Builder stage |

Tags are overwritten with the newest build every day — there is no `latest` tag, so pick a version explicitly.

## Usage

Since production images have no shell or package manager, install dependencies in a `-dev` builder stage and copy them into the hardened final image.

**Python:**

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

**Node.js:**

```dockerfile
FROM teogisis/wolfpack-node:22-dev AS builder
WORKDIR /app
COPY package*.json .
RUN npm ci --omit=dev

FROM teogisis/wolfpack-node:22
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
ENTRYPOINT ["/usr/bin/node", "index.js"]
```

**Java:**

```dockerfile
FROM teogisis/wolfpack-java:21-dev AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn -B package -DskipTests

FROM teogisis/wolfpack-java:21
WORKDIR /app
COPY --from=builder /app/target/app.jar app.jar
ENTRYPOINT ["/usr/bin/java", "-jar", "app.jar"]
```

**.NET:**

```dockerfile
FROM teogisis/wolfpack-dotnet:8-dev AS builder
WORKDIR /app
COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM teogisis/wolfpack-dotnet:8
WORKDIR /app
COPY --from=builder /app/publish .
ENTRYPOINT ["/usr/bin/dotnet", "myapp.dll"]
```

Both variants run as a non-root user (uid/gid `65532`) by default.

## How images are built

Everything lives in this repo and runs on a schedule — nothing is built by hand:

1. **Discover** ([`discover-versions.sh`](.github/scripts/discover-versions.sh)) scans `images/<runtime>/<version>/` and turns every folder it finds into a build target — adding a runtime or version is just adding a folder, no pipeline changes needed.
2. **Build, scan, and publish** ([`build-and-publish.sh`](.github/scripts/build-and-publish.sh)) runs once per target, in parallel: apko builds the image from its `apko.yaml`, [Trivy](https://github.com/aquasecurity/trivy) scans it for CVEs, and the image is pushed to Docker Hub.
3. **Publish SBOMs** collects the SPDX SBOM apko generates for every image and deploys them as a static site via GitHub Pages.
4. **Update this README** collects every scan result and rewrites the tables below.

Source files:

- [`images/<runtime>/<version>/apko.yaml`](images) — the apko config for each image
- [`.github/workflows/build-images.yml`](.github/workflows/build-images.yml) — the daily pipeline
- [`.github/scripts/`](.github/scripts) — the pipeline logic, one script per step

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

Every image ships with an auto-generated SPDX SBOM, regenerated daily and published at **[theo-gkisis.github.io/wolfpack](https://theo-gkisis.github.io/wolfpack/)**.

## Vulnerability scan results

Updated automatically by the daily build pipeline ([Trivy](https://github.com/aquasecurity/trivy)), broken down by runtime.

<!-- TRIVY-TABLE:START -->
### dotnet

| Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |
|---|---|---|---|---|---|---|---|
| 8 | 2 | 6 | 3 | 0 | 0 | 11 | 2026-09-16 |
| 8-dev | 7 | 21 | 8 | 0 | 0 | 36 | 2026-09-16 |
| 10 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 10-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |

### Java

| Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |
|---|---|---|---|---|---|---|---|
| 17 | 0 | 2 | 6 | 1 | 0 | 9 | 2026-09-16 |
| 17-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 21 | 0 | 7 | 16 | 4 | 0 | 27 | 2026-09-16 |
| 21-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |

### Node.js

| Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |
|---|---|---|---|---|---|---|---|
| 20 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 20-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 22 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 22-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |

### Python

| Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |
|---|---|---|---|---|---|---|---|
| 3.10 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 3.10-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 3.11 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 3.11-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 3.12 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 3.12-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 3.13 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 3.13-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 3.14 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |
| 3.14-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-16 |

<!-- TRIVY-TABLE:END -->

## License

[MIT](LICENSE)
