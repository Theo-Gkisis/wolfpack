# Multi-stage build using only our own WolfPack images.
# Production (3.11) has no pip/shell by design (hardened, 0 CVEs) — so
# dependencies are installed in the 3.11-dev builder stage instead.

# ---- Builder stage: our dev image (has pip + busybox shell) ----
FROM wolfpack/python:3.11-dev-amd64 AS builder

WORKDIR /app
COPY requirements.txt .
RUN python3.11 -m pip install --no-cache-dir --target=/app/deps -r requirements.txt

# ---- Final stage: our hardened production image (no pip, no shell) ----
FROM wolfpack/python:3.11-amd64

WORKDIR /app
COPY --from=builder /app/deps /app/deps
COPY app.py .

ENV PYTHONPATH=/app/deps
EXPOSE 8080

ENTRYPOINT ["/usr/bin/python3.11", "/app/app.py"]
