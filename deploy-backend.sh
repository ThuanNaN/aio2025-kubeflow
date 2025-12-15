#!/bin/bash

# Deploy Backend Service Only
# This script deploys only the backend YOLO inference API

set -e

echo "🔧 Deploying Backend Service..."

# Check if minikube is running
if ! minikube status &> /dev/null; then
    echo "❌ Minikube is not running. Please start minikube first."
    exit 1
fi

# Create namespace if it doesn't exist
echo "📦 Ensuring namespace exists..."
kubectl apply -f k8s/shared/namespace.yaml

# Deploy backend
echo "🚀 Deploying backend..."
kubectl apply -f k8s/backend/deployment.yaml
kubectl apply -f k8s/backend/service.yaml
kubectl apply -f k8s/backend/ingress.yaml 2>/dev/null || echo "⚠️  Ingress not available, skipping"

# Wait for deployment to be ready
echo "⏳ Waiting for backend to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/backend -n yolo-app

echo ""
echo "✅ Backend deployment completed!"
echo ""
echo "📊 Backend Status:"
kubectl get pods -n yolo-app -l app=backend
echo ""
kubectl get service -n yolo-app backend-service
echo ""
echo "🌐 Access backend API:"
echo "   $(minikube service backend-service -n yolo-app --url)"
echo ""
echo "💡 To test the API:"
echo "   curl \$(minikube service backend-service -n yolo-app --url)/health"
echo ""
echo "📝 To view logs:"
echo "   kubectl logs -n yolo-app -l app=backend -f"
