#!/bin/bash
set -e

echo "🗑️  Uninstalling YOLO Application Helm release..."

# Configuration
NAMESPACE="yolo-app"
RELEASE_NAME="yolo-app"

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed."
    exit 1
fi

# Check if release exists
if ! helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
    echo "⚠️  Release '$RELEASE_NAME' not found in namespace '$NAMESPACE'"
    exit 0
fi

echo "🔄 Uninstalling Helm release..."
helm uninstall $RELEASE_NAME -n $NAMESPACE

echo "✅ Release uninstalled successfully!"

# Optional: Delete the namespace
read -p "Do you want to delete the namespace '$NAMESPACE'? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Deleting namespace..."
    kubectl delete namespace $NAMESPACE
    echo "✅ Namespace deleted!"
else
    echo "ℹ️  Namespace preserved."
fi
