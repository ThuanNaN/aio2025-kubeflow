# YOLO11n FastAPI service

Run a local server that serves YOLO inference.

Quickstart

1. Create and activate a virtualenv

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

2. Provide your model via `YOLO_MODEL` environment variable or place `yolo11n.pt` next to the server.

```bash
export YOLO_MODEL=/path/to/yolo11n.pt
python main.py
```

3. Predict

POST a file to `/predict` as form `file` (optionally `?return_image=true` to get an annotated image as base64).

Running tests

```bash
pip install pytest
pytest -q
```

Docker
------

Build image from `backend/`:

```bash
cd backend
docker build -t aio2025-kubeflow-backend:latest .
```

Run with a local `model/` volume mounted:

```bash
mkdir -p backend/model
# put your yolo11n.pt into backend/model/
docker run --rm -p 8000:8000 -v $(pwd)/model:/app/model -e YOLO_MODEL=/app/model/yolo11n.pt aio2025-kubeflow-backend:latest
```

Or use `docker-compose` from the repo root:

```bash
docker-compose up --build
```

Notes:
- The included `Dockerfile` is CPU-oriented. For GPU acceleration, use a CUDA base image and install a CUDA-compatible PyTorch build in `requirements.txt` or install `torch` at build time for your target CUDA version.

Model directory notes
---------------------

When running with Docker Compose, the host `backend/model/` directory is mounted into the container. The container must be able to write to this directory so the Ultralytics library can download model weights (`yolo11n.pt`) automatically if they are not present. Either:

- Pre-download the model and place it at `backend/model/yolo11n.pt`, or
- Ensure the host directory is writable by the Docker daemon (the compose file mounts it read-write by default).

If you prefer the host to be read-only, download the model locally first and add the file before starting the containers.

