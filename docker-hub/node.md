# wolfpack-node

Hardened, minimal Node.js container images built on [Wolfi](https://github.com/wolfi-dev) with [apko](https://github.com/chainguard-dev/apko) — no distro, no shell, no package manager in production.

Rebuilt **daily** from Wolfi's rolling-release package repo, so security patches land automatically. Every build is scanned with [Trivy](https://github.com/aquasecurity/trivy); results and an auto-generated SBOM are tracked on [GitHub](https://github.com/Theo-Gkisis/wolfpack).

## Tags

Two variants per Node.js version — `20`, `22`:

| Tag | Contains | Use for |
|---|---|---|
| `<version>` | Node.js + CA certs only. No shell, no npm. | Production runtime |
| `<version>-dev` | Same, plus `npm` and `busybox` (shell). | Builder stage — installing dependencies |

Each tag is overwritten with the newest build; there is no `latest` tag (pick a version explicitly).

## Usage

Since the production image has no shell or npm, install dependencies in a `-dev` builder stage and copy them into the hardened final image:

```dockerfile
# ---- Builder: has npm + shell ----
FROM teogisis/wolfpack-node:22-dev AS builder
WORKDIR /app
COPY package*.json .
RUN npm ci --omit=dev

# ---- Final: hardened, no npm, no shell ----
FROM teogisis/wolfpack-node:22
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
ENTRYPOINT ["/usr/bin/node", "index.js"]
```

Runs as a non-root user (uid/gid `65532`) by default.

## Also in this family

[`wolfpack-python`](https://hub.docker.com/r/teogisis/wolfpack-python) · [`wolfpack-java`](https://hub.docker.com/r/teogisis/wolfpack-java) · [`wolfpack-dotnet`](https://hub.docker.com/r/teogisis/wolfpack-dotnet)

## Source

Build configs, CI pipeline, and up-to-date vulnerability scan results: [github.com/Theo-Gkisis/wolfpack](https://github.com/Theo-Gkisis/wolfpack)
