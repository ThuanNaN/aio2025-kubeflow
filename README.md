# AI VIETNAM - AIO 2025 - Kubeflow

This repository contains the code and resources for the AI VIETNAM - AIO 2025 project using Kubeflow. The project aims to leverage Kubeflow's capabilities for building, deploying, and managing machine learning workflows on Kubernetes.

## Repository Structure

- **backend/** - FastAPI backend with YOLO11n inference API
- **frontend/** - Gradio web interface for image upload and prediction
- **stress-test/** - Standalone stress testing service for benchmarking the backend API

## Branch Structure

- `code/be-fe`: This branch contains the backend and frontend code for this project.
- `docker-only`: This branch contains Docker Compose and Docker Swarm configurations for local development and testing.
- `tutor/k8s`: This branch includes configurations and resources for deploying the project on Kubernetes.
- `tutor/k8s-helm`: This branch contains Helm charts for easier deployment and management of the project on Kubernetes.
- `tutor/kubeflow`: This branch includes Kubeflow-specific configurations and resources for integrating the project with Kubeflow.

## Stress Testing

The `stress-test/` directory contains a standalone service for load testing and benchmarking the backend API. It supports testing both local and deployed backends with configurable test profiles.

**Quick Start:**
```bash
cd stress-test
pip install -r requirements.txt

# Run quick benchmark on local backend
./run_stress_test.sh --env local --profile quick

# Run interactive Locust web UI
./run_stress_test.sh --env local --mode web

# Test deployed backend
./run_stress_test.sh --url https://your-backend-url --profile standard
```

See [stress-test/README.md](stress-test/README.md) for detailed documentation.
