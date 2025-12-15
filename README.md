# AI VIETNAM - AIO 2025 - Kubeflow

A foundation of tools for AI platforms on Kubernetes. This project demonstrates deploying a YOLO11n object detection service using Docker and Kubernetes, featuring a FastAPI backend and Gradio frontend interface.

## 📋 Overview

This project provides a complete end-to-end solution for deploying AI inference services with:

- **Backend**: FastAPI service serving YOLO11n object detection model
- **Frontend**: Gradio web interface for easy interaction
- **Deployment**: Docker Compose for local development and Kubernetes manifests for production

## 🏗️ Architecture

```
┌─────────────────┐
│  Gradio Frontend│
│   (Port 7860)   │
└────────┬────────┘
         │ HTTP
         ▼
┌─────────────────┐
│  FastAPI Backend│
│   (Port 8000)   │
│   YOLO11n Model │
└─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Python 3.9+ (for local development)
- YOLO11n model file (`yolo11n.pt`)

### Using Docker Compose (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/ThuanNaN/aio2025-kubeflow.git
   cd aio2025-kubeflow
   ```

2. **Place the YOLO model**
   ```bash
   mkdir -p backend/model
   # Place your yolo11n.pt file in backend/model/
   ```

3. **Start the services**
   ```bash
   docker-compose up --build
   ```

4. **Access the application**
   - Frontend: http://localhost:7860
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs

### Local Development

#### Backend

1. **Setup environment**
   ```bash
   cd backend
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Set model path**
   ```bash
   export YOLO_MODEL=/path/to/yolo11n.pt
   ```

3. **Run the server**
   ```bash
   python main.py
   ```

#### Frontend

1. **Setup environment**
   ```bash
   cd frontend
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Configure backend URL** (optional)
   ```bash
   export BACKEND_URL=http://localhost:8000/predict
   ```

3. **Run the app**
   ```bash
   python gradio_app.py
   ```

## 🔧 Configuration

### Backend Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `YOLO_MODEL` | Path to YOLO model file | `yolo11n.pt` |

### Frontend Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BACKEND_URL` | Backend API endpoint | `http://localhost:8000/predict` |

## 📡 API Endpoints

### POST `/predict`

Performs object detection on an uploaded image.

**Parameters:**
- `file`: Image file (multipart/form-data)
- `return_image`: Optional boolean query parameter to return annotated image as base64

**Response:**
```json
{
  "predictions": [
    {
      "class": "person",
      "confidence": 0.95,
      "bbox": [x1, y1, x2, y2]
    }
  ],
  "image": "base64_encoded_string"  // if return_image=true
}
```

## 🧪 Testing

Run backend tests:

```bash
cd backend
pip install pytest
pytest -q
```

## 🐳 Docker

### Building Individual Images

**Backend:**
```bash
cd backend
docker build -t aio2025-kubeflow-backend:latest .
docker run --rm -p 8000:8000 \
  -v $(pwd)/model:/app/model \
  -e YOLO_MODEL=/app/model/yolo11n.pt \
  aio2025-kubeflow-backend:latest
```

**Frontend:**
```bash
cd frontend
docker build -t aio2025-kubeflow-frontend:latest .
docker run --rm -p 7860:7860 \
  -e BACKEND_URL=http://host.docker.internal:8000/predict \
  aio2025-kubeflow-frontend:latest
```

## 🐝 Docker Swarm Deployment

For multi-node production deployments with high availability, use Docker Swarm mode. See [SWARM_DEPLOYMENT.md](SWARM_DEPLOYMENT.md) for detailed instructions.

**Quick Swarm Deployment:**

1. **Initial infrastructure setup** (first time only):
   ```bash
   ./deploy-swarm.sh
   ```

2. **Build and push multi-arch images**:
   ```bash
   ./build-and-push.sh
   ```

3. **Deploy the stack**:
   ```bash
   ./deploy-stack.sh
   ```

4. **Scale services** (optional):
   ```bash
   ./scale-swarm.sh --auto   # Auto-scale based on nodes
   ./scale-swarm.sh backend 3  # Manual scaling
   ```

5. **Cleanup when done** (optional):
   ```bash
   ./cleanup-swarm.sh        # Remove stack only
   ./cleanup-swarm.sh --all  # Remove everything
   ```

The Swarm deployment supports:
- Multi-architecture builds (amd64 + arm64)
- High availability with backend replicas across multiple nodes
- Rolling updates with automatic rollback
- Resource limits and reservations
- Health checks and automatic restart
- Dynamic service scaling (manual and auto-scale)
- Automated cleanup and resource management

## ☸️ Kubernetes Deployment

Kubernetes manifests will be available in the `k8s/` directory for production deployments on Kubernetes clusters.

## 📂 Project Structure

```
aio2025-kubeflow/
├── backend/
│   ├── api.py                    # FastAPI application and endpoints
│   ├── main.py                   # Entry point for backend server
│   ├── Dockerfile                # Backend container definition
│   ├── requirements.txt          # Python dependencies
│   ├── model/                    # YOLO model files
│   └── tests/                    # Backend tests
├── frontend/
│   ├── gradio_app.py             # Gradio web interface
│   ├── Dockerfile                # Frontend container definition
│   └── requirements.txt          # Python dependencies
├── docker-compose.yml            # Local development orchestration
├── docker-compose.swarm.yml      # Docker Swarm stack definition
├── deploy-swarm.sh               # Swarm infrastructure setup script
├── build-and-push.sh             # Multi-arch image build script
├── deploy-stack.sh               # Stack deployment script
├── scale-swarm.sh                # Service scaling script
├── cleanup-swarm.sh              # Cleanup and resource removal script
├── SWARM_DEPLOYMENT.md           # Docker Swarm deployment guide
└── README.md                     # This file
```

## 🛠️ Technology Stack

- **Backend Framework**: FastAPI
- **ML Framework**: Ultralytics YOLO
- **Frontend Framework**: Gradio
- **Server**: Uvicorn
- **Containerization**: Docker, Docker Compose
- **Orchestration**: Docker Swarm, Kubernetes (planned)
- **Multi-Architecture**: Docker Buildx for amd64/arm64 support

## 📝 Notes

- The YOLO11n model will be automatically downloaded if not present (requires internet connection)
- For production deployments, consider using persistent volumes for model storage
- The frontend connects to the backend via environment variable configuration
- API documentation is automatically generated and available at `/docs` endpoint

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is part of the AIO 2025 Kubeflow tutorial series.

## 🔗 Related Documentation

- [Docker Swarm Deployment Guide](SWARM_DEPLOYMENT.md) - Complete guide for production multi-node deployment
- [Backend README](backend/README.md) - Backend service details
- [Frontend README](frontend/README.md) - Frontend application details
- [Ultralytics YOLO](https://docs.ultralytics.com/) - YOLO model documentation
- [FastAPI Documentation](https://fastapi.tiangolo.com/) - FastAPI framework
- [Gradio Documentation](https://www.gradio.app/docs/) - Gradio interface
- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/) - Docker Swarm mode
