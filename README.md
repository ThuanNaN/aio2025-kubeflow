# AIO 2025 - Kubeflow MLOps Platform

A comprehensive MLOps platform for YOLO object detection on Kubernetes, featuring:

- **Backend API**: FastAPI service for YOLO11n inference
- **Frontend UI**: Gradio web interface for interactive object detection
- **Kubeflow Components**: Modular pipeline components for data validation, versioning, model training, registry, and deployment
- **Streaming Pipeline**: Kafka-based video processing with detection consumers

## Quick Start

### Backend Service

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python main.py  # Runs on http://localhost:8000
```

### Frontend UI

```bash
cd frontend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python gradio_app.py  # Runs on http://localhost:7860
```

## Architecture

```plantext
├── .github/workflows/  # CI/CD pipelines
├── backend/          # YOLO FastAPI inference service
└── frontend/         # Gradio web UI
```
