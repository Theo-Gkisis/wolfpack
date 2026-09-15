# wolfpack

Hardened, minimal container base images built on [Wolfi](https://github.com/wolfi-dev) with [apko](https://github.com/chainguard-dev/apko) — no shell, no package manager, no unnecessary packages in production. Rebuilt daily so security patches land automatically, and every build is scanned with [Trivy](https://github.com/aquasecurity/trivy) (results below).

## Images

| Runtime | Docker Hub repo | Versions |
|---|---|---|
| Python | [`teogisis/wolfpack-python`](https://hub.docker.com/r/teogisis/wolfpack-python) | 3.10, 3.11, 3.12, 3.13, 3.14 |
| Node.js | [`teogisis/wolfpack-node`](https://hub.docker.com/r/teogisis/wolfpack-node) | 20, 22 |
| Java | [`teogisis/wolfpack-java`](https://hub.docker.com/r/teogisis/wolfpack-java) | 17, 21 |

Each version has two tags:

| Tag | Contains | Use for |
|---|---|---|
| `<version>` | Runtime + CA certs only. No shell, no package manager. | Production |
| `<version>-dev` | Same, plus the language's package manager (`pip` / `npm` / `maven`) and a shell (`busybox`). | Builder stage |

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

Both run as a non-root user (uid/gid `65532`) by default.

## How images are built

- [`images/<runtime>/<version>/apko.yaml`](images) — the apko config for each image
- [`.github/workflows/build-images.yml`](.github/workflows/build-images.yml) — daily CI: builds, pushes, scans with Trivy, updates the table below
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

## License

[MIT](LICENSE)

## Vulnerability scan results

Updated automatically by the daily build pipeline (Trivy).

<!-- TRIVY-TABLE:START -->
| Runtime | Image tag | Critical | High | Medium | Low | Unknown | Total | Last scanned (UTC) |
|---|---|---|---|---|---|---|---|---|
| node | 20 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| node | 20-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| node | 22 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| node | 22-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| python | 3.10 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| python | 3.10-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| python | 3.11 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| python | 3.11-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| python | 3.12 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| python | 3.12-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| python | 3.13 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| python | 3.13-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| python | 3.14 | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
| python | 3.14-dev | 0 | 0 | 1 | 0 | 0 | 1 | 2026-09-15 |
<!-- TRIVY-TABLE:END -->
