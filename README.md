# YOLO Object Detection on Kubernetes

A production-ready YOLO11n object detection application deployed on Kubernetes with FastAPI backend and Gradio frontend.

## Architecture

- **Backend**: FastAPI service with YOLO11n model inference (Port 8000)
- **Frontend**: Gradio web UI for interactive object detection (Port 7860)
- **Deployment**: Kubernetes manifests for minikube/cloud deployment

## Quick Start

### Local Development

See the branches `docker-only` for Docker-based local development without Kubernetes.

### Minikube Deployment

```bash
# Deploy with one command
./deploy-minikube.sh

# Access services
minikube service frontend-service -n yolo-app
minikube dashboard

# View metrics
kubectl top pods -n yolo-app
```

## Project Structure

```plaintext
├── backend/              # FastAPI YOLO inference service
├── frontend/             # Gradio web interface
├── k8s/                  # Kubernetes manifests
└── deploy-minikube.sh    # Automated deployment script
```
