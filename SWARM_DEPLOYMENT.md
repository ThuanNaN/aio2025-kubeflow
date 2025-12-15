# Docker Swarm Deployment Guide

Complete guide for deploying the YOLO11n object detection service on Docker Swarm with multi-architecture support and high availability.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Multi-Architecture Support](#multi-architecture-support)
- [Monitoring and Management](#monitoring-and-management)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## 🎯 Overview

This deployment uses Docker Swarm mode to provide:

- **High Availability**: Backend replicas distributed across multiple nodes
- **Multi-Architecture**: Support for both amd64 and arm64 platforms
- **Rolling Updates**: Zero-downtime deployments with automatic rollback
- **Resource Management**: CPU and memory limits/reservations
- **Load Balancing**: Built-in ingress load balancing across replicas
- **Service Discovery**: Automatic DNS-based service discovery

## 📦 Prerequisites

### Required Software

- Docker Engine 20.10+ with Swarm mode support
- Docker Buildx for multi-architecture builds
- Bash shell (macOS/Linux)
- Network connectivity between cluster nodes

### Hardware Requirements

**Manager Node:**
- 2+ CPU cores
- 4GB+ RAM
- 20GB+ disk space

**Worker Nodes:**
- 1+ CPU cores
- 2GB+ RAM per node
- 10GB+ disk space

### Network Requirements

- All nodes must be on the same network or have connectivity
- Required ports open:
  - **2377/tcp**: Cluster management
  - **7946/tcp & udp**: Node communication
  - **4789/udp**: Overlay network traffic
  - **5001/tcp**: Local Docker registry
  - **8000/tcp**: Backend API
  - **7860/tcp**: Frontend interface

## 🏗️ Architecture

### Cluster Topology

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Swarm Cluster                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐         ┌──────────────────┐      │
│  │  Manager Node    │         │  Worker Node(s)  │      │
│  │  (arm64/amd64)   │         │  (arm64/amd64)   │      │
│  ├──────────────────┤         ├──────────────────┤      │
│  │ ✓ Frontend       │         │ ✓ Backend        │      │
│  │ ✓ Backend        │         │   (Replica)      │      │
│  │ ✓ Registry       │         │                  │      │
│  └──────────────────┘         └──────────────────┘      │
│                                                         │
│           Overlay Network: yolo-network                 │
└─────────────────────────────────────────────────────────┘
```

### Service Architecture

```
Internet
    │
    ▼
┌─────────────────┐
│  Ingress Load   │
│    Balancer     │
└────────┬────────┘
         │
         ├──────────────┬──────────────┐
         ▼              ▼              ▼
    ┌─────────┐    ┌─────────┐   ┌─────────┐
    │Frontend │    │ Backend │   │ Backend │
    │:7860    │    │ Replica │   │ Replica │
    │         │    │  :8000  │   │  :8000  │
    └─────────┘    └─────────┘   └─────────┘
         │              │              │
         └──────────────┴──────────────┘
                    │
            ┌───────┴────────┐
            │ YOLO11n Model  │
            │  (Embedded)    │
            └────────────────┘
```

## 🚀 Quick Start

### Three-Script Workflow

The deployment is divided into three separate scripts for clear separation of concerns:

#### 1. Infrastructure Setup (First Time Only)

Initialize Docker Swarm, verify nodes, and set up the local registry:

```bash
./deploy-swarm.sh
```

**What it does:**
- Initializes Docker Swarm mode
- Verifies all cluster nodes
- Creates local Docker registry service
- Displays node information and next steps

**Run this:** Only once during initial cluster setup or when adding new nodes.

#### 2. Build and Push Images

Build multi-architecture images and push to the registry:

```bash
./build-and-push.sh
```

**What it does:**
- Sets up Docker Buildx with multi-arch support
- Builds backend image for amd64 and arm64
- Builds frontend image for amd64 and arm64
- Pushes images to local registry
- Verifies images in registry catalog

**Run this:** Whenever you make code changes to backend or frontend.

#### 3. Deploy the Stack

Deploy or update the stack from pre-built images:

```bash
./deploy-stack.sh
```

**What it does:**
- Checks Swarm status
- Verifies registry accessibility
- Deploys/updates the yolo-stack
- Shows running services and tasks

**Run this:** To deploy initially or update running services after new images are built.

### Complete Deployment Flow

```bash
# First time setup
./deploy-swarm.sh

# Build images (after code changes)
./build-and-push.sh

# Deploy the stack
./deploy-stack.sh
```

## 🔧 Detailed Setup

### Step 1: Initial Infrastructure Setup

Run the infrastructure setup script:

```bash
./deploy-swarm.sh
```

**Expected Output:**
```
==============================================
Docker Swarm Deployment - Infrastructure Setup
==============================================

[1/4] Initializing Docker Swarm...
✓ Docker Swarm initialized
  Manager IP: 192.168.1.213

[2/4] Verifying cluster nodes...
✓ Found 2 nodes in the cluster

[3/4] Setting up local Docker registry...
✓ Registry service created at 192.168.1.213:5001

[4/4] Next Steps
================

Current Swarm Nodes:
ID            HOSTNAME   STATUS  AVAILABILITY  MANAGER STATUS
abc123...     orbstack   Ready   Active        Leader
def456...     ubuntu     Ready   Active        

Registry Address: 192.168.1.213:5001

Next Steps:
1. Build and push images:    ./build-and-push.sh
2. Deploy the stack:          ./deploy-stack.sh
```

### Step 2: Build Multi-Architecture Images

Build images for both amd64 and arm64 platforms:

```bash
./build-and-push.sh
```

**Expected Output:**
```
==============================================
Building and Pushing Multi-Arch Images
==============================================

[1/4] Setting up multi-arch builder...
✓ Buildx builder 'multi-arch-insecure' ready

[2/4] Building backend image (amd64 + arm64)...
✓ Backend image built and pushed

[3/4] Building frontend image (amd64 + arm64)...
✓ Frontend image built and pushed

[4/4] Verifying images in registry...
✓ Images available in registry:
  - yolo-backend
  - yolo-frontend

Build complete! Images ready for deployment.
```

**Build Details:**
- Uses Docker Buildx with `docker-container` driver
- Builds for platforms: `linux/amd64,linux/arm64`
- Creates multi-arch manifest lists
- Pushes directly to local registry
- Supports insecure HTTP registry

### Step 3: Deploy the Stack

Deploy the services to the Swarm cluster:

```bash
./deploy-stack.sh
```

**Expected Output:**
```
==============================================
Deploying YOLO Stack from Registry
==============================================

[1/4] Checking Docker Swarm status...
✓ Docker Swarm is active

[2/4] Checking registry accessibility...
✓ Registry is accessible at 192.168.1.213:5001

[3/4] Deploying stack 'yolo-stack'...
✓ Stack deployed successfully

[4/4] Service Status
====================

Services:
ID            NAME                  MODE        REPLICAS
abc123...     yolo-stack_backend    replicated  2/2
def456...     yolo-stack_frontend   replicated  1/1

Running Tasks:
NAME                    NODE      DESIRED STATE  CURRENT STATE
yolo-stack_backend.1    orbstack  Running        Running 10 seconds ago
yolo-stack_backend.2    ubuntu    Running        Running 10 seconds ago
yolo-stack_frontend.1   orbstack  Running        Running 10 seconds ago

Access the application:
- Frontend: http://192.168.1.213:7860
- Backend:  http://192.168.1.213:8000
- API Docs: http://192.168.1.213:8000/docs
```

## 🌐 Multi-Architecture Support

### Why Multi-Architecture?

Supporting multiple CPU architectures allows:
- **Flexibility**: Deploy on different hardware (Intel, AMD, ARM)
- **Cost Optimization**: Use ARM instances for better price/performance
- **Edge Deployment**: Deploy on ARM-based edge devices
- **Apple Silicon**: Run on M1/M2/M3 Mac machines

### Supported Platforms

- `linux/amd64`: x86_64 processors (Intel, AMD)
- `linux/arm64`: ARM64 processors (Apple Silicon, AWS Graviton, Raspberry Pi 4+)

### How It Works

1. **Docker Buildx** creates platform-specific images
2. **Manifest lists** reference all architecture variants
3. **Docker automatically** pulls the correct image for each node's architecture
4. Services run natively without emulation

### Verification

Check image manifest:

```bash
# Get registry IP
REGISTRY=$(docker service inspect registry --format '{{.Endpoint.VirtualIPs}}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

# Inspect manifest
docker manifest inspect ${REGISTRY}:5001/yolo-backend:latest
```

Expected output shows multiple architectures:

```json
{
  "manifests": [
    {
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    },
    {
      "platform": {
        "architecture": "arm64",
        "os": "linux"
      }
    }
  ]
}
```

## 📊 Monitoring and Management

### Check Service Status

```bash
# List all services
docker stack services yolo-stack

# Detailed service info
docker service ps yolo-stack_backend --no-trunc
docker service ps yolo-stack_frontend --no-trunc
```

### View Service Logs

```bash
# Backend logs (all replicas)
docker service logs yolo-stack_backend

# Frontend logs
docker service logs yolo-stack_frontend

# Follow logs in real-time
docker service logs -f yolo-stack_backend

# Last 50 lines
docker service logs --tail 50 yolo-stack_backend
```

### Check Running Tasks

```bash
# Show all running tasks
docker stack ps yolo-stack --filter "desired-state=running"

# Show all tasks (including failed/shutdown)
docker stack ps yolo-stack

# Tasks on specific node
docker node ps ubuntu
```

### Inspect Service Configuration

```bash
# Backend service details
docker service inspect yolo-stack_backend --pretty

# Frontend service details
docker service inspect yolo-stack_frontend --pretty
```

### Scale Services

```bash
# Scale backend to 3 replicas
docker service scale yolo-stack_backend=3

# Scale backend to 1 replica
docker service scale yolo-stack_backend=1
```

### Update Services

```bash
# Update backend image
docker service update --image ${REGISTRY}:5001/yolo-backend:latest yolo-stack_backend

# Update with rolling update parameters
docker service update \
  --update-parallelism 1 \
  --update-delay 10s \
  --image ${REGISTRY}:5001/yolo-backend:latest \
  yolo-stack_backend
```

### Node Management

```bash
# List all nodes
docker node ls

# Inspect node
docker node inspect orbstack --pretty

# Drain node (stop scheduling new tasks)
docker node update --availability drain ubuntu

# Activate node
docker node update --availability active ubuntu
```

## 🔍 Troubleshooting

### Services Not Starting

**Symptom:** Tasks stuck in "Pending" or "Preparing" state

**Check:**
```bash
# See error details
docker service ps yolo-stack_backend --no-trunc

# Common issues:
# - "no suitable node": Check node constraints
# - "unsupported platform": Missing architecture in image
# - "image not found": Registry not accessible
```

**Solutions:**
1. Verify multi-arch images exist:
   ```bash
   curl http://${REGISTRY}:5001/v2/yolo-backend/tags/list
   ```

2. Check node architectures:
   ```bash
   docker node inspect $(docker node ls -q) --format '{{.ID}}: {{.Description.Platform.Architecture}}'
   ```

3. Verify registry is accessible:
   ```bash
   curl http://${REGISTRY}:5001/v2/_catalog
   ```

### Image Pull Errors

**Symptom:** "failed to resolve reference", "http: server gave HTTP response to HTTPS client"

**Solution:** Ensure buildx builder has insecure registry configured:

```bash
# Check builder config
docker buildx inspect multi-arch-insecure

# Recreate if needed
./build-and-push.sh
```

### Backend Not Responding

**Check logs:**
```bash
docker service logs yolo-stack_backend | grep -i error
```

**Common issues:**
- Model file not found: Ensure model is in image (check Dockerfile COPY)
- Port conflicts: Check if port 8000 is available
- Memory issues: Check resource limits

**Verify model in container:**
```bash
# Get container ID
CONTAINER_ID=$(docker ps | grep backend | awk '{print $1}' | head -1)

# Check model exists
docker exec $CONTAINER_ID ls -lh /app/model/
```

### Frontend Can't Reach Backend

**Symptom:** Connection refused or timeout errors in frontend

**Check:**
```bash
# Verify backend service exists
docker service ls | grep backend

# Check overlay network
docker network inspect yolo-network

# Test connectivity from frontend container
docker exec $(docker ps | grep frontend | awk '{print $1}') curl http://backend:8000/docs
```

### Registry Issues

**Symptom:** Cannot push images or pull from registry

**Check registry service:**
```bash
# Verify registry is running
docker service ps registry

# Check registry logs
docker service logs registry

# Test registry
curl http://$(hostname -I | awk '{print $1}'):5001/v2/_catalog
```

**Restart registry if needed:**
```bash
docker service update --force registry
```

### Node Failures

**Symptom:** Node shown as "Down" in `docker node ls`

**Steps:**
1. SSH to the failed node
2. Check Docker daemon: `systemctl status docker`
3. Check network connectivity
4. Rejoin the node if needed

### Performance Issues

**Check resource usage:**
```bash
# Node resources
docker node inspect orbstack --format '{{.Description.Resources}}'

# Service resource limits
docker service inspect yolo-stack_backend --format '{{.Spec.TaskTemplate.Resources}}'

# Container stats
docker stats
```

**Adjust resources in docker-compose.swarm.yml:**
```yaml
resources:
  limits:
    cpus: '2'      # Increase if needed
    memory: 4G     # Increase if needed
```

Then update:
```bash
docker stack deploy -c docker-compose.swarm.yml yolo-stack
```

## ⚙️ Advanced Configuration

### Custom Registry Port

Edit `docker-compose.swarm.yml` and scripts:

```bash
# Change registry port in deploy-swarm.sh
sed -i 's/5001/5002/g' deploy-swarm.sh build-and-push.sh deploy-stack.sh

# Update REGISTRY variable
export REGISTRY=192.168.1.213:5002
```

### Resource Limits

Edit [docker-compose.swarm.yml](docker-compose.swarm.yml):

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'        # Max 2 CPU cores
          memory: 4G       # Max 4GB RAM
        reservations:
          cpus: '1'        # Reserved 1 CPU core
          memory: 2G       # Reserved 2GB RAM
```

### Placement Constraints

Control where services run:

```yaml
services:
  backend:
    deploy:
      placement:
        constraints:
          - node.role == worker           # Only on worker nodes
          - node.labels.gpu == true       # Only on GPU nodes
          - node.hostname != node1        # Exclude specific node
```

### Update Configuration

Control rolling update behavior:

```yaml
services:
  backend:
    deploy:
      update_config:
        parallelism: 2      # Update 2 tasks at once
        delay: 10s          # Wait 10s between batches
        failure_action: rollback  # Rollback on failure
        max_failure_ratio: 0.3    # Max 30% failures
```

### Health Checks

Add health checks for better reliability:

```yaml
services:
  backend:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/docs"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Persistent Volumes

For data persistence across updates:

```yaml
services:
  backend:
    volumes:
      - backend-data:/app/data
      
volumes:
  backend-data:
    driver: local
```

### Secrets Management

For sensitive configuration:

```bash
# Create secret
echo "my-secret-key" | docker secret create api_key -

# Use in service
services:
  backend:
    secrets:
      - api_key
      
secrets:
  api_key:
    external: true
```

### Network Configuration

Custom overlay network settings:

```yaml
networks:
  yolo-network:
    driver: overlay
    attachable: true
    driver_opts:
      encrypted: "true"      # Encrypt network traffic
    ipam:
      config:
        - subnet: 10.0.0.0/24
```

## 🔄 Update Workflow

### Updating Application Code

1. **Make code changes** in backend or frontend
2. **Rebuild images:**
   ```bash
   ./build-and-push.sh
   ```
3. **Deploy update:**
   ```bash
   ./deploy-stack.sh
   ```

The stack will perform a rolling update automatically.

### Updating Stack Configuration

1. **Edit docker-compose.swarm.yml**
2. **Deploy changes:**
   ```bash
   ./deploy-stack.sh
   ```

Docker will reconfigure services without rebuilding images.

### Rolling Back

If an update fails:

```bash
# Rollback to previous version
docker service rollback yolo-stack_backend

# Or redeploy specific version
docker service update --image ${REGISTRY}:5001/yolo-backend:v1.0 yolo-stack_backend
```

## 🧹 Cleanup

### Automated Cleanup Script

Use the cleanup script for safe and automated resource cleanup:

```bash
# Remove only the stack (safe, default)
./cleanup-swarm.sh

# Same as above
./cleanup-swarm.sh --stack-only

# Remove stack but keep images (faster redeployment)
./cleanup-swarm.sh --keep-images

# Remove everything (stack, registry, images, leave swarm)
./cleanup-swarm.sh --all
```

**What it does:**
- Shows current status before cleanup
- Asks for confirmation before proceeding
- Removes services gracefully
- Waits for complete shutdown
- Cleans up networks and resources
- Provides next steps after cleanup

**Cleanup Options:**

| Command | Stack | Registry | Images | Leave Swarm |
|---------|-------|----------|--------|-------------|
| `./cleanup-swarm.sh` | ✓ | - | - | - |
| `./cleanup-swarm.sh --stack-only` | ✓ | - | - | - |
| `./cleanup-swarm.sh --keep-images` | ✓ | - | - | - |
| `./cleanup-swarm.sh --all` | ✓ | ✓ | ✓ | ✓ |

### Manual Cleanup (Alternative)

If you prefer manual cleanup:

**Remove Stack:**
```bash
# Remove all services
docker stack rm yolo-stack

# Wait for services to stop
docker stack ps yolo-stack
```

**Remove Registry:**
```bash
docker service rm registry
```

**Clean Images:**
```bash
# Remove YOLO images
docker images | grep yolo | awk '{print $3}' | xargs docker rmi

# Remove unused images
docker image prune -a

# Clean build cache
docker builder prune -a
docker buildx rm multi-arch-insecure
```

**Remove Networks:**
```bash
docker network rm yolo-network
```

**Leave Swarm:**
```bash
# On worker nodes
docker swarm leave

# On manager node (force if last manager)
docker swarm leave --force
```

## 📚 Additional Resources

- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Docker Registry Documentation](https://docs.docker.com/registry/)
