#!/bin/bash
set -e

echo "🚀 Deploying YOLO Application with Helm..."

# Configuration
NAMESPACE="yolo-app"
CHART_PATH="./helm/yolo-app"
RELEASE_NAME="yolo-app"

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    echo "Visit: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if minikube is running (optional)
if command -v minikube &> /dev/null; then
    if ! minikube status &> /dev/null; then
        echo "⚠️  Minikube is not running. Starting minikube..."
        minikube start
    fi
fi

echo "📦 Linting Helm chart..."
helm lint $CHART_PATH

echo "🔍 Checking if release already exists..."
if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
    echo "♻️  Upgrading existing release..."
    helm upgrade $RELEASE_NAME $CHART_PATH \
        --namespace $NAMESPACE \
        --wait \
        --timeout 5m
else
    echo "📥 Installing new release..."
    helm install $RELEASE_NAME $CHART_PATH \
        --namespace $NAMESPACE \
        --create-namespace \
        --wait \
        --timeout 5m
fi

echo "✅ Deployment successful!"
echo ""
echo "📊 Release Status:"
helm status $RELEASE_NAME -n $NAMESPACE

echo ""
echo "🔍 Pod Status:"
kubectl get pods -n $NAMESPACE

echo ""
echo "🌐 Services:"
kubectl get svc -n $NAMESPACE

echo ""
echo "🚪 Ingress:"
kubectl get ingress -n $NAMESPACE

echo ""
echo "💡 To access the application:"
echo "   Run: kubectl port-forward -n $NAMESPACE svc/frontend-service 7860:80"
echo "   Then visit: http://localhost:7860"
