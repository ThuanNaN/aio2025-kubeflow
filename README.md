# YOLO11n Object Detection Service

A containerized AI inference service featuring YOLO11n object detection with FastAPI backend and Gradio frontend interface.

## 🚀 Quick Start

**Prerequisites:** Docker, Docker Compose, and YOLO11n model file (`yolo11n.pt`)

1. **Clone and setup**
   ```bash
   git clone https://github.com/ThuanNaN/aio2025-kubeflow.git
   cd aio2025-kubeflow
   mkdir -p backend/model
   # Place yolo11n.pt in backend/model/
   ```

2. **Run with Docker Compose**
   ```bash
   docker-compose up --build
   ```

3. **Run with Docker Swarm**
   ```bash
   # Setup Docker Swarm (if not already done)
   ./deploy-swarm.sh
    
    # Deploy the stack app
   ./deploy-stack.sh
   ```

## 📁 Project Structure

```
├── .github/workflows/   # CI/CD workflows
├── docs/                # Documentation files
├── backend/             # FastAPI service (port 8000)
│   ├── api.py           # YOLO inference endpoints
│   └── model/           # YOLO11n model directory
├── frontend/            # Gradio interface (port 7860)
│   └── gradio_app.py
├── deploy-stack.sh      # Deployment script for Docker Stack
├── deploy-swarm.sh      # Deployment script for Docker Swarm
├── docker-compose.yml   # Docker Compose configuration
└── SWARM_DEPLOYMENT.md  # Docker Swarm deployment guide
```
