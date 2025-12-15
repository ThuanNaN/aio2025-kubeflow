# Gradio YOLO Frontend

This is a small Gradio app that demonstrates the YOLO11n backend API.

Requirements

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Run

```bash
# By default it will call http://localhost:8000/predict
python gradio_app.py
```

You can change the backend URL with `BACKEND_URL` env var, e.g.: `export BACKEND_URL=http://host.docker.internal:8000/predict`.

Docker
------

Build and run alongside the backend with `docker-compose`:

```bash
docker-compose up --build
# frontend will be available at http://localhost:7860
```

Or build/run just the frontend:

```bash
cd frontend
docker build -t aio2025-kubeflow-frontend:latest .
docker run --rm -p 7860:7860 -e BACKEND_URL=http://host.docker.internal:8000/predict aio2025-kubeflow-frontend:latest
```
