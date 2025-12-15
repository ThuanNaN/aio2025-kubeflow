#!/bin/bash

# Docker Swarm Registry Checker Script
# This script checks the status and contents of the Docker registry

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REGISTRY_HOST="${REGISTRY_HOST:-192.168.1.213}"
REGISTRY_PORT="${REGISTRY_PORT:-5001}"
REGISTRY_URL="${REGISTRY_HOST}:${REGISTRY_PORT}"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Docker Registry Status Checker${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e "${CYAN}Registry: ${REGISTRY_URL}${NC}"
echo ""

# Function to check if registry is accessible
check_registry_connection() {
    echo -e "${BLUE}[1/4] Checking registry connection...${NC}"
    
    if curl -s --connect-timeout 5 "http://${REGISTRY_URL}/v2/" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Registry is accessible${NC}"
        return 0
    else
        echo -e "${RED}✗ Registry is not accessible${NC}"
        echo -e "${YELLOW}Tip: Make sure the registry is running and accessible at ${REGISTRY_URL}${NC}"
        return 1
    fi
}

# Function to list all repositories in the registry
list_repositories() {
    echo -e "\n${BLUE}[2/4] Listing repositories...${NC}"
    
    REPOS=$(curl -s "http://${REGISTRY_URL}/v2/_catalog" | grep -o '"repositories":\[.*\]' | sed 's/"repositories":\[\(.*\)\]/\1/' | tr -d '"' | tr ',' '\n')
    
    if [ -z "$REPOS" ]; then
        echo -e "${YELLOW}⚠ No repositories found in registry${NC}"
        return 1
    else
        echo -e "${GREEN}Found repositories:${NC}"
        echo "$REPOS" | while read -r repo; do
            if [ -n "$repo" ]; then
                echo -e "  ${CYAN}• ${repo}${NC}"
            fi
        done
        return 0
    fi
}

# Function to list tags for a specific repository
list_tags() {
    local repo=$1
    echo -e "\n${BLUE}[3/4] Listing tags for repository: ${repo}${NC}"
    
    TAGS=$(curl -s "http://${REGISTRY_URL}/v2/${repo}/tags/list" | grep -o '"tags":\[.*\]' | sed 's/"tags":\[\(.*\)\]/\1/' | tr -d '"' | tr ',' '\n')
    
    if [ -z "$TAGS" ]; then
        echo -e "${YELLOW}⚠ No tags found for ${repo}${NC}"
    else
        echo -e "${GREEN}Tags for ${repo}:${NC}"
        echo "$TAGS" | while read -r tag; do
            if [ -n "$tag" ]; then
                echo -e "  ${CYAN}• ${tag}${NC}"
            fi
        done
    fi
}

# Function to get image details with architecture
get_image_details() {
    echo -e "\n${BLUE}[4/4] Getting detailed image information with architecture...${NC}"
    
    REPOS=$(curl -s "http://${REGISTRY_URL}/v2/_catalog" | grep -o '"repositories":\[.*\]' | sed 's/"repositories":\[\(.*\)\]/\1/' | tr -d '"' | tr ',' '\n')
    
    echo "$REPOS" | while read -r repo; do
        if [ -n "$repo" ]; then
            TAGS=$(curl -s "http://${REGISTRY_URL}/v2/${repo}/tags/list" | grep -o '"tags":\[.*\]' | sed 's/"tags":\[\(.*\)\]/\1/' | tr -d '"' | tr ',' '\n')
            
            echo ""
            echo -e "${CYAN}Repository: ${repo}${NC}"
            echo "$TAGS" | while read -r tag; do
                if [ -n "$tag" ]; then
                    # Get manifest to extract architecture details
                    MANIFEST=$(curl -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
                              "http://${REGISTRY_URL}/v2/${repo}/manifests/${tag}")
                    
                    # Try to get manifest list for multi-arch images
                    MANIFEST_LIST=$(curl -s -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json" \
                                   "http://${REGISTRY_URL}/v2/${repo}/manifests/${tag}")
                    
                    # Check if it's a manifest list (multi-arch)
                    if echo "$MANIFEST_LIST" | grep -q "manifests"; then
                        echo -e "  ${GREEN}✓${NC} ${REGISTRY_URL}/${repo}:${tag}"
                        
                        # Extract architectures from manifest list
                        ARCHS=$(echo "$MANIFEST_LIST" | grep -o '"platform":{[^}]*}' | \
                               grep -o '"architecture":"[^"]*"' | cut -d'"' -f4 | sort -u)
                        
                        if [ -n "$ARCHS" ]; then
                            echo -e "    ${YELLOW}Architectures:${NC}"
                            echo "$ARCHS" | while read -r arch; do
                                if [ -n "$arch" ]; then
                                    echo -e "      • ${arch}"
                                fi
                            done
                        fi
                    else
                        # Single architecture image
                        # Get config blob to find architecture
                        CONFIG_DIGEST=$(echo "$MANIFEST" | grep -o '"config":{[^}]*}' | \
                                      grep -o '"digest":"[^"]*"' | cut -d'"' -f4)
                        
                        if [ -n "$CONFIG_DIGEST" ]; then
                            CONFIG=$(curl -s "http://${REGISTRY_URL}/v2/${repo}/blobs/${CONFIG_DIGEST}")
                            ARCH=$(echo "$CONFIG" | grep -o '"architecture":"[^"]*"' | cut -d'"' -f4)
                            OS=$(echo "$CONFIG" | grep -o '"os":"[^"]*"' | head -1 | cut -d'"' -f4)
                            
                            # Extract size information
                            SIZE=$(echo "$MANIFEST" | grep -o '"size":[0-9]*' | head -1 | cut -d':' -f2)
                            
                            SIZE_INFO=""
                            if [ -n "$SIZE" ]; then
                                SIZE_MB=$((SIZE / 1024 / 1024))
                                SIZE_INFO=" ${YELLOW}(~${SIZE_MB}MB)${NC}"
                            fi
                            
                            if [ -n "$ARCH" ] && [ -n "$OS" ]; then
                                echo -e "  ${GREEN}✓${NC} ${REGISTRY_URL}/${repo}:${tag}${SIZE_INFO}"
                                echo -e "    ${YELLOW}Platform:${NC} ${OS}/${ARCH}"
                            else
                                echo -e "  ${GREEN}✓${NC} ${REGISTRY_URL}/${repo}:${tag}${SIZE_INFO}"
                            fi
                        else
                            echo -e "  ${GREEN}✓${NC} ${REGISTRY_URL}/${repo}:${tag}"
                        fi
                    fi
                fi
            done
        fi
    done
}

# Function to check specific images
check_specific_images() {
    echo -e "\n${BLUE}Checking for YOLO stack images...${NC}"
    
    local images=("yolo-backend" "yolo-frontend")
    
    for img in "${images[@]}"; do
        if curl -s "http://${REGISTRY_URL}/v2/${img}/tags/list" | grep -q "latest"; then
            echo -e "${GREEN}✓ ${img}:latest found${NC}"
        else
            echo -e "${RED}✗ ${img}:latest not found${NC}"
        fi
    done
}

# Main execution
main() {
    if ! check_registry_connection; then
        exit 1
    fi
    
    if list_repositories; then
        # Get all repositories and list their tags
        REPOS=$(curl -s "http://${REGISTRY_URL}/v2/_catalog" | grep -o '"repositories":\[.*\]' | sed 's/"repositories":\[\(.*\)\]/\1/' | tr -d '"' | tr ',' '\n')
        
        echo "$REPOS" | while read -r repo; do
            if [ -n "$repo" ]; then
                list_tags "$repo"
            fi
        done
        
        get_image_details
        check_specific_images
    fi
    
    echo ""
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${GREEN}Registry check complete!${NC}"
    echo -e "${BLUE}=====================================${NC}"
}

# Parse command line arguments
case "${1}" in
    -h|--help)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -h, --help          Show this help message"
        echo "  -r, --registry      Specify registry (default: ${REGISTRY_URL})"
        echo ""
        echo "Environment variables:"
        echo "  REGISTRY_HOST       Registry hostname (default: 192.168.1.213)"
        echo "  REGISTRY_PORT       Registry port (default: 5001)"
        echo ""
        echo "Examples:"
        echo "  $0"
        echo "  REGISTRY_HOST=localhost $0"
        echo "  $0 -r 192.168.1.213:5001"
        exit 0
        ;;
    -r|--registry)
        REGISTRY_URL="${2}"
        shift 2
        ;;
esac

# Run main function
main
