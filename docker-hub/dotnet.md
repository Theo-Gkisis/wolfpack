# wolfpack-dotnet

Hardened, minimal .NET container images built on [Wolfi](https://github.com/wolfi-dev) with [apko](https://github.com/chainguard-dev/apko) — no distro, no shell, no SDK in production.

Rebuilt **daily** from Wolfi's rolling-release package repo, so security patches land automatically. Every build is scanned with [Trivy](https://github.com/aquasecurity/trivy); results and an auto-generated SBOM are tracked on [GitHub](https://github.com/Theo-Gkisis/wolfpack).

## Tags

Two variants per .NET version — `8`, `10` (LTS):

| Tag | Contains | Use for |
|---|---|---|
| `<version>` | .NET runtime + CA certs only. No shell, no SDK. | Production runtime |
| `<version>-dev` | Full SDK, plus `busybox` (shell). | Builder stage — restoring and publishing |

Each tag is overwritten with the newest build; there is no `latest` tag (pick a version explicitly).

## Usage

Since the production image has no shell or SDK, publish in a `-dev` builder stage and copy the output into the hardened final image:

```dockerfile
# ---- Builder: has SDK + shell ----
FROM teogisis/wolfpack-dotnet:8-dev AS builder
WORKDIR /app
COPY . .
RUN dotnet publish -c Release -o /app/publish

# ---- Final: hardened, no SDK, no shell ----
FROM teogisis/wolfpack-dotnet:8
WORKDIR /app
COPY --from=builder /app/publish .
ENTRYPOINT ["/usr/bin/dotnet", "myapp.dll"]
```

Runs as a non-root user (uid/gid `65532`) by default. `DOTNET_RUNNING_IN_CONTAINER` and `ASPNETCORE_HTTP_PORTS` are set in both variants.

## Also in this family

[`wolfpack-python`](https://hub.docker.com/r/teogisis/wolfpack-python) · [`wolfpack-node`](https://hub.docker.com/r/teogisis/wolfpack-node) · [`wolfpack-java`](https://hub.docker.com/r/teogisis/wolfpack-java)

## Source

Build configs, CI pipeline, and up-to-date vulnerability scan results: [github.com/Theo-Gkisis/wolfpack](https://github.com/Theo-Gkisis/wolfpack)
