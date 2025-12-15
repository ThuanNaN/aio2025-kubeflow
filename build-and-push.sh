#!/bin/bash

# Build and Push Multi-Architecture Images Script
# This script builds Docker images for multiple architectures and pushes them to the registry

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGISTRY_PORT="5001"
BUILDER_NAME="multi-arch-insecure"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Build and Push Multi-Arch Images${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Get host IP
get_host_ip() {
    HOST_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")
    echo "${HOST_IP}"
}

# Setup buildx builder with insecure registry support
setup_builder() {
    echo -e "${BLUE}[1/4] Setting up Docker Buildx builder...${NC}"
    
    # Check if builder exists
    if docker buildx ls | grep -q "${BUILDER_NAME}"; then
        echo -e "${YELLOW}Builder ${BUILDER_NAME} already exists${NC}"
        docker buildx use ${BUILDER_NAME}
    else
        echo -e "${YELLOW}Creating new builder: ${BUILDER_NAME}${NC}"
        
        # Create buildkitd config for insecure registry
        REGISTRY_ADDR=$(get_host_ip)
        cat > /tmp/buildkitd.toml << EOF
[registry."${REGISTRY_ADDR}:${REGISTRY_PORT}"]
  http = true
  insecure = true
EOF
        
        # Create builder
        docker buildx create \
            --name ${BUILDER_NAME} \
            --driver docker-container \
            --driver-opt network=host \
            --config /tmp/buildkitd.toml \
            --use \
            --bootstrap
        
        echo -e "${GREEN}✓ Builder created and bootstrapped${NC}"
    fi
}

# Build and push backend image
build_backend() {
    echo -e "${BLUE}[2/4] Building backend image for multiple architectures...${NC}"
    
    REGISTRY_ADDR=$(get_host_ip)
    export REGISTRY="${REGISTRY_ADDR}:${REGISTRY_PORT}"
    
    echo -e "${YELLOW}Building for linux/amd64 and linux/arm64...${NC}"
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -t ${REGISTRY}/yolo-backend:latest \
        --push \
        ./backend
    
    echo -e "${GREEN}✓ Backend image built and pushed${NC}"
}

# Build and push frontend image
build_frontend() {
    echo -e "${BLUE}[3/4] Building frontend image for multiple architectures...${NC}"
    
    REGISTRY_ADDR=$(get_host_ip)
    export REGISTRY="${REGISTRY_ADDR}:${REGISTRY_PORT}"
    
    echo -e "${YELLOW}Building for linux/amd64 and linux/arm64...${NC}"
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -t ${REGISTRY}/yolo-frontend:latest \
        --push \
        ./frontend
    
    echo -e "${GREEN}✓ Frontend image built and pushed${NC}"
}

# Verify images in registry
verify_images() {
    echo -e "${BLUE}[4/4] Verifying images in registry...${NC}"
    
    REGISTRY_ADDR=$(get_host_ip)
    
    echo -e "${YELLOW}Checking registry catalog...${NC}"
    curl -s http://${REGISTRY_ADDR}:${REGISTRY_PORT}/v2/_catalog | jq '.' || echo "Registry catalog check complete"
    
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}Build and Push Complete!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo -e "${BLUE}Images available at:${NC}"
    echo -e "  Backend:  ${GREEN}${REGISTRY_ADDR}:${REGISTRY_PORT}/yolo-backend:latest${NC}"
    echo -e "  Frontend: ${GREEN}${REGISTRY_ADDR}:${REGISTRY_PORT}/yolo-frontend:latest${NC}"
    echo ""
    echo -e "${YELLOW}Next step:${NC} Run ${BLUE}./deploy-stack.sh${NC} to deploy from registry"
    echo ""
}

# Main execution
main() {
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi
    
    setup_builder
    build_backend
    build_frontend
    verify_images
}

# Run main function
main
