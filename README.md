# 🎯 YOLO Object Detection on Kubernetes

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm&logoColor=white)](https://helm.sh/)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![YOLO](https://img.shields.io/badge/YOLO-00FFFF?style=flat&logo=yolo&logoColor=black)](https://github.com/ultralytics/ultralytics)

> A production-ready YOLO11n object detection application deployed on Kubernetes with complete monitoring stack using Prometheus and Grafana.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Deployment Options](#-deployment-options)
- [Accessing Services](#-accessing-services)
- [Usage Guide](#-usage-guide)
- [Configuration](#-configuration)
- [Monitoring](#-monitoring)
- [Operations](#-operations)
- [Troubleshooting](#-troubleshooting)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Overview

This project demonstrates a complete MLOps pipeline for deploying a YOLO11n object detection model on Kubernetes. It includes:

- **Backend**: FastAPI service providing REST API for YOLO11n inference
- **Frontend**: Interactive Gradio web UI for real-time object detection
- **Monitoring**: Prometheus + Grafana stack for metrics and visualization
- **Orchestration**: Kubernetes deployment with Helm charts for easy management

Perfect for learning Kubernetes, MLOps practices, or as a template for production ML deployments.

---

## ✨ Features

### Core Functionality
- ✅ **YOLO11n Object Detection** - Fast and accurate real-time detection
- ✅ **RESTful API** - FastAPI backend with automatic OpenAPI documentation
- ✅ **Interactive UI** - Gradio web interface with image/webcam support
- ✅ **Health Checks** - Liveness and readiness probes for reliability

### Kubernetes & DevOps
- ✅ **Helm Charts** - Parameterized deployments with sensible defaults
- ✅ **Multi-Replica Deployment** - High availability with load balancing
- ✅ **Horizontal Pod Autoscaling** - Automatic scaling based on metrics
- ✅ **Ingress Support** - Production-ready routing configuration
- ✅ **Resource Management** - Requests and limits for optimal performance

### Monitoring & Observability
- ✅ **Prometheus Integration** - Comprehensive metrics collection
- ✅ **Grafana Dashboards** - Pre-configured visualization dashboards
- ✅ **Persistent Storage** - Retained metrics and dashboard configurations
- ✅ **Custom Metrics** - Application-specific monitoring

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────────┐
│                     yolo-app namespace                     │
│                                                            │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   Frontend   │────────▶│   Backend    │                 │
│  │   (Gradio)   │         │   (FastAPI)  │                 │
│  │   Port: 7860 │         │   Port: 8000 │                 │
│  │  Replicas: 2 │         │  Replicas: 2 │                 │
│  └──────────────┘         └──────────────┘                 │
│         │                         │                        │
│         │                         ▼                        │
│         │                  ┌──────────────┐                │
│         │                  │  Prometheus  │                │
│         │                  │  Port: 9090  │                │
│         │                  │  Storage:10Gi│                │
│         │                  └──────────────┘                │
│         │                         │                        │
│         │                         ▼                        │
│         │                  ┌──────────────┐                │
│         └─────────────────▶│   Grafana    │                │
│                            │  Port: 3000  │                │
│                            │  Storage: 5Gi│                │
│                            └──────────────┘                │
│                                                            │
│  Services: LoadBalancer / ClusterIP / Ingress              │
│  Storage: PersistentVolumeClaims                           │
└────────────────────────────────────────────────────────────┘
```

### Component Details

| Component | Technology | Port | Replicas | Purpose |
|-----------|-----------|------|----------|---------|
| Frontend | Gradio | 7860 | 2 | User interface for object detection |
| Backend | FastAPI + YOLO11n | 8000 | 2 | ML inference API |
| Prometheus | Prometheus | 9090 | 1 | Metrics collection and storage |
| Grafana | Grafana | 3000 | 1 | Metrics visualization |

---

## 📦 Prerequisites

### Required
- **Kubernetes Cluster** (v1.24+)
  - Local: [Minikube](https://minikube.sigs.k8s.io/) or [Kind](https://kind.sigs.k8s.io/)
  - Cloud: GKE, EKS, AKS, or any managed K8s
- **kubectl** (v1.24+) - [Install Guide](https://kubernetes.io/docs/tasks/tools/)
- **Helm** (v3.0+) - [Install Guide](https://helm.sh/docs/intro/install/)

### Optional
- **Docker** - For building custom images
- **Git** - For cloning the repository

### System Requirements

**Minimum (Minikube):**
```bash
minikube start --cpus=4 --memory=8192 --disk-size=20g
```

**Recommended (with monitoring):**
```bash
minikube start --cpus=8 --memory=16384 --disk-size=50g
```

### Verify Installation
```bash
# Check kubectl
kubectl version --client

# Check Helm
helm version

# Check Kubernetes cluster
kubectl cluster-info
```

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/ThuanNaN/aio2025-kubeflow.git
cd aio2025-kubeflow
```

### 2. Deploy with One Command
```bash
./deploy-helm.sh
```

This script will:
- Create the `yolo-app` namespace
- Deploy backend and frontend services
- Deploy Prometheus and Grafana
- Configure persistent storage
- Set up all necessary services

### 3. Wait for Pods to be Ready
```bash
kubectl get pods -n yolo-app -w
```

Expected output:
```
NAME                          READY   STATUS    RESTARTS   AGE
backend-xxxxxxxxxx-xxxxx      1/1     Running   0          2m
backend-xxxxxxxxxx-xxxxx      1/1     Running   0          2m
frontend-xxxxxxxxxx-xxxxx     1/1     Running   0          2m
frontend-xxxxxxxxxx-xxxxx     1/1     Running   0          2m
prometheus-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
grafana-xxxxxxxxxx-xxxxx      1/1     Running   0          2m
```

### 4. Access the Application
```bash
# Frontend (Main Application)
kubectl port-forward -n yolo-app svc/frontend-service 7860:80
```

Open http://localhost:7860 in your browser 🎉

---

## 🔧 Deployment Options

### Option 1: Helm Deployment (Recommended)

**Full Deployment with Monitoring:**
```bash
./deploy-helm.sh
```

**Custom Configuration:**
```bash
helm install yolo-app ./helm/yolo-app \
  --namespace yolo-app \
  --create-namespace \
  --set backend.replicaCount=3 \
  --set frontend.replicaCount=2 \
  --set monitoring.enabled=true
```

**Minimal Deployment (No Monitoring):**
```bash
helm install yolo-app ./helm/yolo-app \
  --namespace yolo-app \
  --create-namespace \
  --set monitoring.enabled=false
```

### Option 2: Local Development

For Docker-only development without Kubernetes:
```bash
# Switch to docker-only branch
git checkout docker-only

# Follow instructions in that branch
```

### Cleanup
```bash
# Using script
./undeploy-helm.sh

# Or manually
helm uninstall yolo-app -n yolo-app
kubectl delete namespace yolo-app
```

---

## 🌐 Accessing Services

### Frontend Application
```bash
kubectl port-forward -n yolo-app svc/frontend-service 7860:80
```
- **URL**: http://localhost:7860
- **Description**: Interactive Gradio UI for object detection

### Backend API
```bash
kubectl port-forward -n yolo-app svc/backend-service 8000:8000
```
- **URL**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

### Grafana Dashboards
```bash
kubectl port-forward -n yolo-app svc/grafana-service 3000:80
```
- **URL**: http://localhost:3000
- **Username**: `admin`
- **Password**: `admin123`

### Prometheus Metrics
```bash
kubectl port-forward -n yolo-app svc/prometheus-service 9090:9090
```
- **URL**: http://localhost:9090
- **Targets**: http://localhost:9090/targets

### Using Minikube Service (Alternative)
```bash
# Frontend
minikube service frontend-service -n yolo-app

# Backend
minikube service backend-service -n yolo-app

# Get all service URLs
minikube service list -n yolo-app
```

---

## 📖 Usage Guide

### Using the Web Interface

1. **Access Frontend**: Open http://localhost:7860
2. **Upload Image**: Click "Upload" or drag & drop an image
3. **Or Use Webcam**: Enable webcam for real-time detection
4. **Adjust Confidence**: Set confidence threshold (default: 0.25)
5. **Detect Objects**: Click "Detect" button
6. **View Results**: See bounding boxes and labels on the image

### Using the API

**Health Check:**
```bash
curl http://localhost:8000/health
```

**Detect Objects:**
```bash
curl -X POST "http://localhost:8000/detect" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@path/to/image.jpg" \
  -F "confidence=0.25"
```

**API Documentation:**
Visit http://localhost:8000/docs for interactive Swagger UI

### Using Monitoring

**Grafana Dashboards:**
1. Login to Grafana (http://localhost:3000)
2. Navigate to **Dashboards** → **Browse**
3. Open **"YOLO App - Kubernetes Metrics"**
4. View real-time metrics:
   - CPU & Memory usage
   - Pod count and status
   - Network I/O
   - Request rates

**Prometheus Queries:**
Access http://localhost:9090 and try these queries:
```promql
# CPU usage per pod
rate(container_cpu_usage_seconds_total{namespace="yolo-app"}[5m])

# Memory usage
container_memory_usage_bytes{namespace="yolo-app"}

# Pod count
count(kube_pod_info{namespace="yolo-app"})

# HTTP requests (if instrumented)
rate(http_requests_total{namespace="yolo-app"}[5m])
```

---

## ⚙️ Configuration

### Helm Values

Edit [helm/yolo-app/values.yaml](helm/yolo-app/values.yaml) or override with `--set`:

**Backend Configuration:**
```yaml
backend:
  replicaCount: 2
  image:
    repository: your-registry/yolo-backend
    tag: "latest"
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "2000m"
```

**Frontend Configuration:**
```yaml
frontend:
  replicaCount: 2
  image:
    repository: your-registry/yolo-frontend
    tag: "latest"
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
```

**Monitoring Configuration:**
```yaml
monitoring:
  enabled: true
  prometheus:
    storage: 10Gi
    retention: 15d
  grafana:
    adminPassword: "admin123"
    storage: 5Gi
```

### Update Configuration
```bash
helm upgrade yolo-app ./helm/yolo-app \
  --namespace yolo-app \
  --set backend.replicaCount=5 \
  --set monitoring.grafana.adminPassword=NewSecurePassword
```

---

## 📊 Monitoring

### Pre-configured Dashboards

The deployment includes Grafana dashboards for:
- **Kubernetes Metrics**: Pod CPU, Memory, Network
- **Application Metrics**: Request rates, latencies
- **System Overview**: Cluster health and resource usage

### Adding Custom Metrics

**Backend (Python/FastAPI):**
```python
from prometheus_client import Counter, Histogram

# Add to your backend code
detection_counter = Counter('yolo_detections_total', 'Total detections')
detection_duration = Histogram('yolo_detection_duration_seconds', 'Detection time')
```

### Alerts Configuration

Prometheus can be configured for alerting. Edit [helm/yolo-app/templates/prometheus-configmap.yaml](helm/yolo-app/templates/prometheus-configmap.yaml).

---

## 🔨 Operations

### Scaling

**Scale Backend:**
```bash
kubectl scale deployment backend -n yolo-app --replicas=5
```

**Scale Frontend:**
```bash
kubectl scale deployment frontend -n yolo-app --replicas=3
```

**Using Helm:**
```bash
helm upgrade yolo-app ./helm/yolo-app \
  --set backend.replicaCount=5 \
  --set frontend.replicaCount=3 \
  --namespace yolo-app
```

### Viewing Logs

**Backend Logs:**
```bash
kubectl logs -n yolo-app -l app=backend -f
```

**Frontend Logs:**
```bash
kubectl logs -n yolo-app -l app=frontend -f
```

**All Logs:**
```bash
kubectl logs -n yolo-app --all-containers=true -f
```

### Updating Images

**Update to New Version:**
```bash
helm upgrade yolo-app ./helm/yolo-app \
  --set backend.image.tag=v1.1.0 \
  --set frontend.image.tag=v1.1.0 \
  --namespace yolo-app
```

**Force Rollout:**
```bash
kubectl rollout restart deployment/backend -n yolo-app
kubectl rollout restart deployment/frontend -n yolo-app
```

### Resource Monitoring

**Pod Resource Usage:**
```bash
kubectl top pods -n yolo-app
```

**Node Resource Usage:**
```bash
kubectl top nodes
```

**Detailed Pod Info:**
```bash
kubectl describe pod <pod-name> -n yolo-app
```

---

## 🐛 Troubleshooting

### Pods Not Starting

**Check Pod Status:**
```bash
kubectl get pods -n yolo-app
kubectl describe pod <pod-name> -n yolo-app
```

**Check Logs:**
```bash
kubectl logs <pod-name> -n yolo-app
kubectl logs <pod-name> -n yolo-app --previous  # For crashed pods
```

**Common Issues:**
- **ImagePullBackOff**: Check image name and registry access
- **CrashLoopBackOff**: Check application logs for errors
- **Pending**: Check resource availability and PVC status

### Services Not Accessible

**Check Service Status:**
```bash
kubectl get svc -n yolo-app
kubectl get endpoints -n yolo-app
```

**Test Internal Connectivity:**
```bash
kubectl run debug -it --rm --image=curlimages/curl --restart=Never -n yolo-app -- \
  curl http://backend-service:8000/health
```

**Check Port Forwards:**
```bash
# Kill existing port-forwards
pkill -f "port-forward"

# Create new port-forward
kubectl port-forward -n yolo-app svc/frontend-service 7860:80
```

### Storage Issues

**Check PVC Status:**
```bash
kubectl get pvc -n yolo-app
kubectl describe pvc <pvc-name> -n yolo-app
```

**Check Storage Class:**
```bash
kubectl get storageclass
```

**Enable Storage (Minikube):**
```bash
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
```

### No Data in Grafana

**1. Verify Prometheus is Running:**
```bash
kubectl get pods -n yolo-app -l app=prometheus
```

**2. Check Prometheus Targets:**
```bash
kubectl port-forward -n yolo-app svc/prometheus-service 9090:9090
# Open http://localhost:9090/targets
# Verify all targets show "UP"
```

**3. Check Grafana Data Source:**
- Login to Grafana
- Go to **Configuration** → **Data Sources**
- Select Prometheus
- Click **"Test"** button

**4. Restart Grafana:**
```bash
kubectl delete pod -n yolo-app -l app=grafana
```

### Performance Issues

**Check Resource Limits:**
```bash
kubectl describe pod <pod-name> -n yolo-app | grep -A 5 "Limits"
```

**Increase Resources:**
```bash
helm upgrade yolo-app ./helm/yolo-app \
  --set backend.resources.limits.memory=4Gi \
  --set backend.resources.limits.cpu=4000m \
  --namespace yolo-app
```

### Reset Everything

**Complete Reset:**
```bash
./undeploy-helm.sh
./deploy-helm.sh
```

**Or Manually:**
```bash
helm uninstall yolo-app -n yolo-app
kubectl delete namespace yolo-app
kubectl create namespace yolo-app
helm install yolo-app ./helm/yolo-app --namespace yolo-app
```

---

## 📁 Project Structure

```
.
├── backend/                      # FastAPI Backend Service
│   ├── api.py                   # API endpoints
│   ├── main.py                  # FastAPI application
│   ├── requirements.txt         # Python dependencies
│   ├── Dockerfile              # Backend container image
│   ├── model/                  # YOLO model files
│   │   └── yolo11n.pt
│   └── tests/                  # Unit tests
│       └── test_api.py
│
├── frontend/                     # Gradio Frontend Application
│   ├── gradio_app.py           # Gradio UI application
│   ├── requirements.txt         # Python dependencies
│   └── Dockerfile              # Frontend container image
│
├── helm/                         # Helm Charts
│   └── yolo-app/               # Main Helm chart
│       ├── Chart.yaml          # Chart metadata
│       ├── values.yaml         # Default configuration
│       └── templates/          # K8s manifests templates
│           ├── backend-deployment.yaml
│           ├── backend-service.yaml
│           ├── backend-ingress.yaml
│           ├── frontend-deployment.yaml
│           ├── frontend-service.yaml
│           ├── frontend-ingress.yaml
│           ├── prometheus-deployment.yaml
│           ├── prometheus-service.yaml
│           ├── prometheus-configmap.yaml
│           ├── prometheus-pvc.yaml
│           ├── prometheus-rbac.yaml
│           ├── grafana-deployment.yaml
│           ├── grafana-service.yaml
│           ├── grafana-configmap.yaml
│           ├── grafana-pvc.yaml
│           ├── monitoring-ingress.yaml
│           ├── configmap.yaml
│           └── namespace.yaml
│
├── deploy-helm.sh               # Deployment script
├── undeploy-helm.sh            # Cleanup script
├── README.md                    # This file
└── QUICK-START.md              # Quick reference guide
```
