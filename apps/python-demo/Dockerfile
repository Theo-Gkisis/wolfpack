# Uses only our own WolfPack image — no external base needed.
# No shell in this image, so RUN must use exec (JSON array) form.
FROM wolfpack/python:3.11-amd64

# pip install needs to write to /usr (read-only for nonroot), so switch to
# root just for the install step, then drop back to nonroot for runtime.
USER root
WORKDIR /app

COPY requirements.txt .
RUN ["/usr/bin/python3.11", "-m", "pip", "install", "--no-cache-dir", "-r", "requirements.txt"]

COPY app.py .

USER nonroot
EXPOSE 8080

ENTRYPOINT ["/usr/bin/python3.11", "/app/app.py"]
