# Helm Deployment Guide

This directory contains the Helm chart for deploying the YOLO Object Detection application to Kubernetes.

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- [Helm 3.x](https://helm.sh/docs/intro/install/) installed
- kubectl configured to access your cluster

## Chart Structure

```
helm/yolo-app/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
└── templates/              # Kubernetes manifest templates
    ├── _helpers.tpl        # Helper templates
    ├── NOTES.txt           # Post-installation notes
    ├── namespace.yaml      # Namespace creation
    ├── configmap.yaml      # Application configuration
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── backend-ingress.yaml
    ├── frontend-deployment.yaml
    ├── frontend-service.yaml
    ├── frontend-ingress.yaml
    ├── prometheus-*.yaml   # Prometheus monitoring
    ├── grafana-*.yaml      # Grafana dashboards
    └── monitoring-ingress.yaml
```

## Quick Start

### Deploy the application

```bash
# From the project root directory
./deploy-helm.sh
```

Or manually:

```bash
# Install the chart
helm install yolo-app ./helm/yolo-app \
  --namespace yolo-app \
  --create-namespace

# Check the status
helm status yolo-app -n yolo-app
kubectl get pods -n yolo-app
```

### Undeploy the application

```bash
./undeploy-helm.sh
```

Or manually:

```bash
helm uninstall yolo-app -n yolo-app
kubectl delete namespace yolo-app
```

## Configuration

The `values.yaml` file contains all configurable parameters. You can override these values during installation:

### Common Configuration Options

```bash
# Change replica counts
helm install yolo-app ./helm/yolo-app \
  --set backend.replicaCount=3 \
  --set frontend.replicaCount=2

# Use different image tags
helm install yolo-app ./helm/yolo-app \
  --set backend.image.tag=v1.2.0 \
  --set frontend.image.tag=v1.2.0

# Disable ingress
helm install yolo-app ./helm/yolo-app \
  --set ingress.enabled=false

# Change ingress host
helm install yolo-app ./helm/yolo-app \
  --set ingress.host=yolo.mydomain.com

# Enable/disable monitoring
helm install yolo-app ./helm/yolo-app \
  --set monitoring.enabled=true
```

### Custom Values File

Create a custom values file (e.g., `values-prod.yaml`):

```yaml
backend:
  replicaCount: 5
  image:
    tag: v1.2.0
  resources:
    requests:
      memory: "1Gi"
      cpu: "1000m"

frontend:
  replicaCount: 3
  image:
    tag: v1.2.0

ingress:
  host: yolo.production.com
```

Deploy with custom values:

```bash
helm install yolo-app ./helm/yolo-app \
  -f values-prod.yaml \
  --namespace yolo-app \
  --create-namespace
```

## Upgrading

To upgrade an existing release:

```bash
helm upgrade yolo-app ./helm/yolo-app \
  --namespace yolo-app

# Or with new values
helm upgrade yolo-app ./helm/yolo-app \
  -f values-prod.yaml \
  --namespace yolo-app
```

## Rollback

If something goes wrong, rollback to a previous release:

```bash
# List release history
helm history yolo-app -n yolo-app

# Rollback to previous version
helm rollback yolo-app -n yolo-app

# Rollback to specific revision
helm rollback yolo-app 2 -n yolo-app
```

## Testing

### Lint the chart

```bash
helm lint ./helm/yolo-app
```

### Dry-run installation

```bash
helm install yolo-app ./helm/yolo-app \
  --dry-run \
  --debug \
  --namespace yolo-app
```

### Template rendering

```bash
# See all rendered templates
helm template yolo-app ./helm/yolo-app

# Save to file
helm template yolo-app ./helm/yolo-app > rendered-manifests.yaml
```

## Accessing the Application

After deployment, access the application using one of these methods:

### 1. Port Forward (Development)

```bash
kubectl port-forward -n yolo-app svc/frontend-service 7860:80
```

Then visit: http://localhost:7860

### 2. LoadBalancer (Cloud)

If using a cloud provider with LoadBalancer support:

```bash
kubectl get svc -n yolo-app frontend-service
```

Access the EXTERNAL-IP shown.

### 3. Ingress (Production)

If ingress is enabled and configured:

```
http://yolo.example.com  (or your configured host)
```

### 4. Minikube

```bash
minikube service frontend-service -n yolo-app
```

## Monitoring

### Check pod status

```bash
kubectl get pods -n yolo-app
```

### View logs

```bash
# Backend logs
kubectl logs -n yolo-app -l app=backend -f

# Frontend logs
kubectl logs -n yolo-app -l app=frontend -f

# Prometheus logs
kubectl logs -n yolo-app -l app=prometheus -f

# Grafana logs
kubectl logs -n yolo-app -l app=grafana -f
```

### Describe resources

```bash
kubectl describe deployment backend -n yolo-app
kubectl describe deployment frontend -n yolo-app
```

## Monitoring with Prometheus and Grafana

The chart includes built-in monitoring with Prometheus and Grafana.

### Enable/Disable Monitoring

Monitoring is enabled by default. To disable:

```bash
helm install yolo-app ./helm/yolo-app \
  --set monitoring.enabled=false
```

| `monitoring.enabled` | Enable Prometheus & Grafana | `true` |
| `monitoring.prometheus.replicaCount` | Prometheus replicas | `1` |
| `monitoring.prometheus.scrapeInterval` | Metrics scrape interval | `15s` |
| `monitoring.prometheus.retention` | Metrics retention period | `15d` |
| `monitoring.prometheus.storage.size` | Prometheus storage size | `10Gi` |
| `monitoring.grafana.replicaCount` | Grafana replicas | `1` |
| `monitoring.grafana.adminUser` | Grafana admin username | `admin` |
| `monitoring.grafana.adminPassword` | Grafana admin password | `admin123` |
| `monitoring.grafana.storage.size` | Grafana storage size | `5Gi` |
### Access Prometheus

```bash
# Port forward
kubectl port-forward -n yolo-app svc/prometheus-service 9090:9090
```

Then visit: http://localhost:9090

### Access Grafana

```bash
# Port forward
kubectl port-forward -n yolo-app svc/grafana-service 3000:80
```

Then visit: http://localhost:3000

**Default credentials:**
- Username: `admin`
- Password: `admin123`

### Configure Monitoring

You can customize monitoring settings in `values.yaml`:

```yaml
monitoring:
  enabled: true
  
  prometheus:
    replicaCount: 1
    scrapeInterval: 15s
    retention: 15d
    storage:
      enabled: true
      size: 10Gi
  
  grafana:
    replicaCount: 1
    adminUser: admin
    adminPassword: admin123
    storage:
      enabled: true
      size: 5Gi
```

### Grafana Dashboards

The chart includes a pre-configured Kubernetes dashboard showing:
- CPU Usage per pod
- Memory Usage per pod
- Pod count
- Network I/O

To add custom dashboards:
1. Log into Grafana
2. Go to Dashboards → Import
3. Import dashboard from grafana.com or create your own

### Prometheus Targets

Prometheus is configured to scrape:
- Kubernetes API server
- Kubernetes nodes
- All pods in yolo-app namespace (with proper annotations)
- Backend service (http://backend-service:8000/metrics)
- Frontend service (http://frontend-service:80/metrics)
- Prometheus itself

### Custom Metrics

To expose custom metrics from your application:

1. Add Prometheus client library to your app
2. Expose metrics endpoint at `/metrics`
3. Prometheus will auto-discover via service annotations

The services are already annotated for Prometheus discovery:
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8000"
  prometheus.io/path: "/metrics"
```

### Monitoring Storage

By default, both Prometheus and Grafana use persistent storage:
- Prometheus: 10Gi (15 days retention)
- Grafana: 5Gi (dashboards and configs)

To use emptyDir (non-persistent):

```bash
helm install yolo-app ./helm/yolo-app \
  --set monitoring.prometheus.storage.enabled=false \
  --set monitoring.grafana.storage.enabled=false
```

### Ingress for Monitoring

Monitoring services are also exposed via ingress (if enabled):
- Prometheus: http://yolo.example.com/prometheus
- Grafana: http://yolo.example.com/grafana

## Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Kubernetes namespace | `yolo-app` |
| `namespace.create` | Create namespace | `true` |
| `backend.replicaCount` | Number of backend replicas | `2` |
| `backend.image.repository` | Backend image repository | `ghcr.io/thuannan/aio2025-kubeflow/backend` |
| `backend.image.tag` | Backend image tag | `latest` |
| `backend.service.type` | Backend service type | `ClusterIP` |
| `backend.service.port` | Backend service port | `8000` |
| `frontend.replicaCount` | Number of frontend replicas | `2` |
| `frontend.image.repository` | Frontend image repository | `ghcr.io/thuannan/aio2025-kubeflow/frontend` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `frontend.service.type` | Frontend service type | `LoadBalancer` |
| `frontend.service.port` | Frontend service port | `80` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.host` | Ingress hostname | `yolo.example.com` |

For a complete list of parameters, see [values.yaml](yolo-app/values.yaml).

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n yolo-app
kubectl logs <pod-name> -n yolo-app
```

### Service not accessible

```bash
kubectl get svc -n yolo-app
kubectl describe svc frontend-service -n yolo-app
```

### Ingress not working

```bash
kubectl get ingress -n yolo-app
kubectl describe ingress backend-ingress -n yolo-app
kubectl describe ingress frontend-ingress -n yolo-app
```

### Check Helm release

```bash
helm list -n yolo-app
helm status yolo-app -n yolo-app
helm get values yolo-app -n yolo-app
```

## Cleanup

Remove everything:

```bash
helm uninstall yolo-app -n yolo-app
kubectl delete namespace yolo-app
```
- Monitoring with Prometheus and Grafana is enabled by default
- Prometheus scrapes metrics from all annotated services
- Grafana comes with pre-configured dashboards and Prometheus datasource

## Notes

- The chart creates a dedicated namespace by default
- Backend uses ClusterIP service (internal only)
- Frontend uses LoadBalancer service (external access)
- Ingress is enabled by default with nginx ingress class
- Health checks are configured for both services
- Resource limits and requests are set for production use

## Contributing

To modify the chart:

1. Edit `values.yaml` or template files
2. Test with `helm lint ./helm/yolo-app`
3. Test installation with `helm install --dry-run --debug`
4. Update version in `Chart.yaml`
5. Test deployment on a cluster
