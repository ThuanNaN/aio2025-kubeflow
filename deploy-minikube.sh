#!/bin/bash

# Minikube Deployment Script for YOLO Application
# This script deploys the backend and frontend services to minikube

set -e

echo "🚀 Starting Minikube Deployment..."

# Check if minikube is running
if ! minikube status &> /dev/null; then
    echo "❌ Minikube is not running. Starting minikube..."
    # minikube start --cpus=4 --memory=8192 --nodes=1 --driver=docker
    minikube start --cpus=4 --memory=8192 --nodes=2 --driver=docker
else
    echo "✅ Minikube is already running"
fi

# Enable addons for minikube
echo "🔌 Enabling minikube addons..."
minikube addons enable ingress
minikube addons enable dashboard
minikube addons enable metrics-server

# Wait for ingress controller to be ready
echo "⏳ Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s 2>/dev/null || echo "⚠️  Ingress controller not ready, skipping ingress resources"

echo "📥 Using images from GitHub Container Registry (GHCR)..."
echo "   Images will be pulled automatically by Kubernetes"

# Create namespace
echo "📦 Creating namespace..."
kubectl apply -f k8s/shared/namespace.yaml

# Deploy backend (without ingress first)
echo "🔧 Deploying backend..."
kubectl apply -f k8s/backend/deployment.yaml
kubectl apply -f k8s/backend/service.yaml

# Deploy frontend (without ingress first)
echo "🎨 Deploying frontend..."
kubectl apply -f k8s/frontend/deployment.yaml
kubectl apply -f k8s/frontend/service.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/backend -n yolo-app
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n yolo-app

# Deploy HPA (Horizontal Pod Autoscaler)
echo "📊 Deploying Horizontal Pod Autoscalers..."
kubectl apply -f k8s/backend/hpa.yaml
kubectl apply -f k8s/frontend/hpa.yaml

# Deploy ingress resources if ingress controller is ready
if kubectl get deployment -n ingress-nginx ingress-nginx-controller &>/dev/null; then
    echo "🌐 Deploying ingress resources..."
    kubectl apply -f k8s/backend/ingress.yaml 2>/dev/null || echo "⚠️  Could not apply backend ingress"
    kubectl apply -f k8s/frontend/ingress.yaml 2>/dev/null || echo "⚠️  Could not apply frontend ingress"
fi

# Get service URLs
echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n yolo-app
echo ""
kubectl get services -n yolo-app
echo ""
echo "🌐 Access your application:"
echo "   Backend:  $(minikube service backend-service -n yolo-app --url)"
echo "   Frontend: $(minikube service frontend-service -n yolo-app --url)"
echo ""
echo "💡 To open the frontend in your browser, run:"
echo "   minikube service frontend-service -n yolo-app"
echo ""
echo "� To access Kubernetes Dashboard, run:"
echo "   minikube dashboard"
echo ""
echo "📝 To view logs:"
echo "   Backend:  kubectl logs -n yolo-app -l app=backend"
echo "   Frontend: kubectl logs -n yolo-app -l app=frontend"
echo ""
echo "📈 To view metrics:"
echo "   kubectl top nodes"
echo "   kubectl top pods -n yolo-app"
echo ""
echo "🔄 To view autoscaling status:"
echo "   kubectl get hpa -n yolo-app"
echo "   kubectl get hpa -n yolo-app -w  # watch in real-time"
echo ""
echo "� Deploy services separately:"
echo "   Backend:  ./deploy-backend.sh"
echo "   Frontend: ./deploy-frontend.sh"
echo ""
echo "�🗑️  To delete the deployment:"
echo "   kubectl delete namespace yolo-app"
