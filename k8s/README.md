# Kubernetes Deployment Guide

This directory contains Kubernetes manifests and deployment configurations for the YOLO application.

## Architecture

- **Backend**: FastAPI service with YOLO11n model inference (Port 8000)
- **Frontend**: Gradio UI application (Port 7860)
- **Namespace**: `yolo-app`

## Prerequisites

1. Kubernetes cluster (v1.24+)
2. `kubectl` CLI installed and configured
3. Docker Hub account for container registry
4. GitHub repository secrets configured:
   - `DOCKER_USERNAME`: Your Docker Hub username
   - `DOCKER_PASSWORD`: Your Docker Hub access token
   - `KUBE_CONFIG`: Base64-encoded kubeconfig file

## Directory Structure

```
k8s/
├── backend/
│   ├── deployment.yaml         # Backend deployment
│   ├── service.yaml           # Backend service
│   ├── ingress.yaml           # Backend ingress rules
│   └── hpa.yaml               # Backend autoscaling
├── frontend/
│   ├── deployment.yaml         # Frontend deployment
│   ├── service.yaml           # Frontend service
│   ├── ingress.yaml           # Frontend ingress rules
│   └── hpa.yaml               # Frontend autoscaling
├── shared/
│   ├── namespace.yaml         # Namespace definition
│   └── configmap.yaml         # Application configuration
└── README.md                  # This file
```

## Manual Deployment

### 1. Create Namespace

```bash
kubectl apply -f k8s/shared/namespace.yaml
```

### 2. Deploy Backend

```bash
kubectl apply -f k8s/backend/
```

Verify backend deployment:
```bash
kubectl get pods -n yolo-app -l app=backend
kubectl logs -n yolo-app -l app=backend
```

### 3. Deploy Frontend

```bash
kubectl apply -f k8s/frontend/
```

Verify frontend deployment:
```bash
kubectl get pods -n yolo-app -l app=frontend
kubectl logs -n yolo-app -l app=frontend
```

### Deploy All Services

```bash
# Deploy everything at once
kubectl apply -f k8s/shared/
kubectl apply -f k8s/backend/
kubectl apply -f k8s/frontend/
```

### 3. Deploy Frontend

```bash
kubectl apply -f k8s/frontend-deployment.yaml
```

Verify frontend deployment:
```bash
kubectl get pods -n yolo-app -l app=frontend
kubectl logs -n yolo-app -l app=frontend
```

### 4. Check Services

```bash
kubectl get services -n yolo-app
```

### 5. (Optional) Apply ConfigMap

```bash
kubectl apply -f k8s/configmap.yaml
```

### 6. (Optional) Configure Ingress

Edit `ingress.yaml` to set your domain, then:
```bash
kubectl apply -f k8s/ingress.yaml
```

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy-k8s.yaml`) automatically:

1. **Builds Docker images** for backend and frontend
2. **Pushes images** to Docker Hub
3. **Deploys to Kubernetes** on push to `main` or `tutor/k8s` branches

### Setup GitHub Secrets

1. Go to your GitHub repository → Settings → Secrets and variables → Actions
2. Add the following secrets:

   - **DOCKER_USERNAME**: Your Docker Hub username
   - **DOCKER_PASSWORD**: Your Docker Hub access token (create at hub.docker.com/settings/security)
   - **KUBE_CONFIG**: Base64-encoded kubeconfig
     ```bash
     cat ~/.kube/config | base64 -w 0  # Linux
     cat ~/.kube/config | base64       # macOS
     ```

### Trigger Deployment

Push to `main` or `tutor/k8s` branch:
```bash
git add .
git commit -m "Deploy to Kubernetes"
git push origin tutor/k8s
```

Or manually trigger via GitHub Actions UI.

## Accessing the Application

### Local Development (Port Forward)

Backend:
```bash
kubectl port-forward -n yolo-app service/backend-service 8000:8000
```
Access at: http://localhost:8000

Frontend:
```bash
kubectl port-forward -n yolo-app service/frontend-service 7860:80
```
Access at: http://localhost:7860

### Production (LoadBalancer)

Get the external IP:
```bash
kubectl get service frontend-service -n yolo-app
```

Wait for `EXTERNAL-IP` to be assigned, then access the application via that IP.

### With Ingress

If using Ingress with a domain, access via:
- Frontend: https://yolo.example.com
- Backend API: https://yolo.example.com/api

## Scaling

### Horizontal Pod Autoscaling (HPA)

The application includes HorizontalPodAutoscaler configurations for automatic scaling based on CPU and memory usage.

#### Deploy Autoscalers

```bash
# Deploy backend HPA
kubectl apply -f k8s/backend/hpa.yaml

# Deploy frontend HPA
kubectl apply -f k8s/frontend/hpa.yaml
```

#### View Autoscaler Status

```bash
# Check HPA status
kubectl get hpa -n yolo-app

# Watch HPA in real-time
kubectl get hpa -n yolo-app -w

# Detailed HPA information
kubectl describe hpa backend-hpa -n yolo-app
kubectl describe hpa frontend-hpa -n yolo-app
```

#### HPA Configuration

**Backend HPA:**
- Min replicas: 2
- Max replicas: 10
- Triggers: CPU > 70% or Memory > 80%
- Scale up: Fast (up to 4 pods or 100% per 15s)
- Scale down: Conservative (up to 2 pods or 50% per 15s, 5min stabilization)

**Frontend HPA:**
- Min replicas: 2
- Max replicas: 8
- Triggers: CPU > 70% or Memory > 80%
- Scale up: Fast (up to 4 pods or 100% per 15s)
- Scale down: Conservative (up to 2 pods or 50% per 15s, 5min stabilization)

#### Prerequisites for HPA

Ensure metrics-server is installed in your cluster:
```bash
# Check if metrics-server is running
kubectl get deployment metrics-server -n kube-system

# If not installed, deploy metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

For Minikube:
```bash
minikube addons enable metrics-server
```

### Manual Scaling

You can also manually scale deployments (this will be overridden by HPA if deployed):
```bash
# Scale backend
kubectl scale deployment backend -n yolo-app --replicas=3

# Scale frontend
kubectl scale deployment frontend -n yolo-app --replicas=3
```

## Monitoring

View logs:
```bash
# Backend logs
kubectl logs -n yolo-app -l app=backend -f

# Frontend logs
kubectl logs -n yolo-app -l app=frontend -f
```

Check pod status:
```bash
kubectl get pods -n yolo-app -w
```

Describe resources:
```bash
kubectl describe deployment backend -n yolo-app
kubectl describe deployment frontend -n yolo-app
```

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n yolo-app
kubectl logs <pod-name> -n yolo-app
```

### Image pull errors

Verify image names in deployment files match your Docker Hub repository.

### Service connectivity issues

Test backend from frontend pod:
```bash
kubectl exec -it <frontend-pod> -n yolo-app -- curl http://backend-service:8000/
``HorizontalPodAutoscalers are configured for automatic scaling based on resource utilization
- The HPA requires metrics-server to be running in the cluster
- Resource requests and limits are defined to enable proper autoscaling behavior

### Update deployment with new image

```bash
kubectl set image deployment/backend backend=thuannan/yolo-backend:new-tag -n yolo-app
kubectl set image deployment/frontend frontend=thuannan/yolo-frontend:new-tag -n yolo-app
```

## Resource Management

View resource usage:
```bash
kubectl top pods -n yolo-app
kubectl top nodes
```

## Cleanup

Delete all resources:
```bash
kubectl delete namespace yolo-app
```

Or delete specific resources:
```bash
kubectl delete -f k8s/frontend-deployment.yaml
kubectl delete -f k8s/backend-deployment.yaml
kubectl delete -f k8s/namespace.yaml
```

## Configuration

### Environment Variables

Backend:
- `HOST`: Bind host (default: 0.0.0.0)
- `PORT`: Service port (default: 8000)
- `YOLO_MODEL`: Path to YOLO model (default: /app/model/yolo11n.pt)

Frontend:
- `BACKEND_URL`: Backend API endpoint (default: http://backend-service:8000/predict)

### Resource Limits

Adjust in deployment files:
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "2000m"
```

## Notes

- Docker images are tagged with branch names and git SHA
- The pipeline uses Docker layer caching for faster builds
- Health checks ensure pods are ready before receiving traffic
- LoadBalancer service type may require cloud provider support
- For production, consider using HorizontalPodAutoscaler for auto-scaling
