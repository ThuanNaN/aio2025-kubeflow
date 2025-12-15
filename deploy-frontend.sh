#!/bin/bash

# Deploy Frontend Service Only
# This script deploys only the frontend Gradio UI

set -e

echo "🎨 Deploying Frontend Service..."

# Check if minikube is running
if ! minikube status &> /dev/null; then
    echo "❌ Minikube is not running. Please start minikube first."
    exit 1
fi

# Create namespace if it doesn't exist
echo "📦 Ensuring namespace exists..."
kubectl apply -f k8s/shared/namespace.yaml

# Deploy frontend
echo "🚀 Deploying frontend..."
kubectl apply -f k8s/frontend/deployment.yaml
kubectl apply -f k8s/frontend/service.yaml
kubectl apply -f k8s/frontend/ingress.yaml 2>/dev/null || echo "⚠️  Ingress not available, skipping"

# Wait for deployment to be ready
echo "⏳ Waiting for frontend to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n yolo-app

echo ""
echo "✅ Frontend deployment completed!"
echo ""
echo "📊 Frontend Status:"
kubectl get pods -n yolo-app -l app=frontend
echo ""
kubectl get service -n yolo-app frontend-service
echo ""
echo "🌐 Access frontend UI:"
echo "   $(minikube service frontend-service -n yolo-app --url)"
echo ""
echo "💡 To open in browser:"
echo "   minikube service frontend-service -n yolo-app"
echo ""
echo "📝 To view logs:"
echo "   kubectl logs -n yolo-app -l app=frontend -f"
