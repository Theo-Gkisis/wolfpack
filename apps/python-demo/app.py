import os
import platform
import socket
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
@app.get("/health")
def health():
    return jsonify(
        status="ok",
        image="wolfpack/python:3.11",
        python_version=platform.python_version(),
        implementation=platform.python_implementation(),
        hostname=socket.gethostname(),
        uid=os.getuid(),
        gid=os.getgid(),
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
