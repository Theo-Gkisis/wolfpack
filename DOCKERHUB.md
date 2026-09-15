# wolfpack-python

Hardened, minimal Python container images built on [Wolfi](https://github.com/wolfi-dev) with [apko](https://github.com/chainguard-dev/apko) — no distro, no shell, no package manager in production.

Rebuilt **daily** from Wolfi's rolling-release package repo, so security patches land automatically. Every build is scanned with [Trivy](https://github.com/aquasecurity/trivy); results are tracked on [GitHub](https://github.com/Theo-Gkisis/wolfpack).

## Tags

Two variants per Python version — `3.10`, `3.11`, `3.12`, `3.13`, `3.14`:

| Tag | Contains | Use for |
|---|---|---|
| `<version>` | Python + CA certs only. No shell, no pip. | Production runtime |
| `<version>-dev` | Same, plus `pip` and `busybox` (shell). | Builder stage — installing dependencies |

Each tag is overwritten with the newest build; there is no `latest` tag (pick a version explicitly).

## Usage

Since the production image has no shell or pip, install dependencies in a `-dev` builder stage and copy them into the hardened final image:

```dockerfile
# ---- Builder: has pip + shell ----
FROM teogisis/wolfpack-python:3.13-dev AS builder
WORKDIR /app
COPY requirements.txt .
RUN python3.13 -m pip install --no-cache-dir --target=/app/deps -r requirements.txt

# ---- Final: hardened, no pip, no shell ----
FROM teogisis/wolfpack-python:3.13
WORKDIR /app
COPY --from=builder /app/deps /app/deps
COPY app.py .
ENV PYTHONPATH=/app/deps
ENTRYPOINT ["/usr/bin/python3.13", "/app/app.py"]
```

Both images run as a non-root user (uid/gid `65532`) by default.

## Source

Build configs, CI pipeline, and up-to-date vulnerability scan results: [github.com/Theo-Gkisis/wolfpack](https://github.com/Theo-Gkisis/wolfpack)
