#!/bin/bash

# cleanup-swarm.sh - Clean up Docker Swarm stack and resources
# Usage: ./cleanup-swarm.sh [OPTIONS]
# Options:
#   --all         : Remove everything (stack, images, leave swarm)
#   --stack-only  : Remove only the stack (default)
#   --keep-images : Don't remove images when cleaning

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="yolo-stack"

# Parse command line arguments
REMOVE_STACK=true
REMOVE_IMAGES=false
LEAVE_SWARM=false

if [[ "$1" == "--all" ]]; then
    REMOVE_STACK=true
    REMOVE_IMAGES=true
    LEAVE_SWARM=true
elif [[ "$1" == "--stack-only" ]]; then
    REMOVE_STACK=true
    REMOVE_IMAGES=false
    LEAVE_SWARM=false
elif [[ "$1" == "--keep-images" ]]; then
    REMOVE_STACK=true
    REMOVE_IMAGES=false
    LEAVE_SWARM=false
fi

# Print header
echo ""
echo "=============================================="
echo "  Docker Swarm Cleanup Script"
echo "=============================================="
echo ""

# Function to print step
print_step() {
    echo -e "${BLUE}[$1] $2${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to confirm action
confirm_action() {
    local message=$1
    echo -e "${YELLOW}$message${NC}"
    read -p "Are you sure? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        echo "Cancelled."
        exit 0
    fi
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running"
        exit 1
    fi
}

# Check if Swarm is active
check_swarm() {
    if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
        print_warning "Docker Swarm is not active"
        return 1
    fi
    return 0
}

# Remove stack
remove_stack() {
    print_step "1/?" "Removing stack '$STACK_NAME'..."
    
    if ! docker stack ls | grep -q "$STACK_NAME"; then
        print_warning "Stack '$STACK_NAME' not found"
        return 0
    fi
    
    docker stack rm "$STACK_NAME"
    print_success "Stack removal initiated"
    
    # Wait for stack to be fully removed
    echo -n "Waiting for services to stop"
    while docker stack ps "$STACK_NAME" 2>/dev/null | grep -q "."; do
        echo -n "."
        sleep 2
    done
    echo ""
    print_success "Stack '$STACK_NAME' completely removed"
}

# Remove images
remove_images() {
    print_step "2/?" "Removing GHCR images..."
    
    echo "Removing aio2025-kubeflow images from GHCR..."
    
    # Remove backend and frontend images
    local images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "ghcr.io/thuannan/aio2025-kubeflow/" || true)
    
    if [[ -z "$images" ]]; then
        print_warning "No aio2025-kubeflow images found"
    else
        echo "$images" | while read -r image; do
            docker rmi "$image" 2>/dev/null && echo "  - Removed: $image" || true
        done
        print_success "GHCR images removed"
    fi
    
    # Prune unused images
    echo ""
    echo "Pruning unused images..."
    docker image prune -f
    print_success "Unused images pruned"
}

# Clean build cache
clean_build_cache() {
    print_step "4/?" "Cleaning build cache..."
    
    # Check if buildx builder exists
    if docker buildx ls | grep -q "multi-arch-insecure"; then
        docker buildx rm multi-arch-insecure 2>/dev/null || true
        print_success "Buildx builder removed"
    fi
    
    # Prune build cache
    docker builder prune -f
    print_success "Build cache cleaned"
}

# Remove networks
remove_networks() {
  Remove networks
remove_networks() {
    print_step "3ager_count=$(docker node ls --filter "role=manager" -q | wc -l)
        if [[ $manager_count -gt 1 ]]; then
            print_warning "Multiple managers detected. Please demote this node first:"
            echo "  docker node demote $(hostname)"
            return 1
        fi
        
        print_warning "This is the last manager node"
        docker swarm leave --force
        print_success "Left swarm (forced)"
    else4
        docker swarm leave
        print_success "Left swarm"
    fi
}

# Display current status
show_status() {
    echo ""
    echo "Current Status:"
    echo "==============="
    
    # Check stack
    if docker stack ls 2>/dev/null | grep -q "$STACK_NAME"; then
        echo -e "Stack:    ${GREEN}Running${NC}"
    else
        echo -e "Stack:    ${RED}Not found${NC}"
    fi
    
    # Check registry
    if docker service ls 2>/dev/null | grep -q "$REGISTRY_SERVICE"; then
        echo -e "Registry: ${GREEN}Running${NC}"
    else
        echo -e "Registry: ${RED}Not found${NC}"
    fi
    
    # Check swarm
    if check_swarm; then
        echo -e "Swarm:    ${GREEN}Active${NC}"
        local node_count=$(docker node ls -q 2>/dev/null | wc -l)
        echo "Nodes:    $node_count"
    else
        echo -e "Swarm:    ${RED}Inactive${NC}"
    fi
    swarm
    if check_swarm; then
        echo -e "Swarm:    ${GREEN}Active${NC}"
        local node_count=$(docker node ls -q 2>/dev/null | wc -l)
        echo "Nodes:    $node_count"
    else
        echo -e "Swarm:    ${RED}Inactive${NC}"
    fi
    
    # Check images
    local image_count=$(docker images | grep "ghcr.io/thuannan/aio2025-kubeflow/" | wc -l)
    echo "Images:   $image_count GHCRcho "✓ Clean build cache"
    [[ $LEAVE_SWARM == true ]] && echo "✓ Leave Docker Swarm"
    echo ""
    
    # Show current status
    show_status
    
    # Confirm with user
    if [[ $LEAVE_SWARM == true ]]; then
        confirm_action "⚠️  WARNING: This will remove EVERYTHING including leaving the Swarm!"
    else
        confirm_action "This will clean the selected resources."
    fi
    
    echo ""
    
    # Execute cleanup steps
    if ! check_swarm && [[ $REMOVE_STACK == true ]]; then
        print_error "Swarm is not active. Cannot remove stack."
        exit 1
    fi
    
    local step=1
    
    # Remove stack
    if [[ $REMOVE_STACK == true ]]; then
        remove_stack
        ((step++))
    fi
    
    # Remove images
    if [[ $REMOVE_IMAGES == true ]]; then
        remove_images
        ((step++))
    fi
    
    # Remove networks
    if [[ $REMOVE_STACK == true ]]; then
        sleep 2  # Wait a bit for network cleanup
        remove_networks
        ((step++))
    fi
    
    # Leave swarm
    if [[ $LEAVE_SWARM == true ]]; then
        leave_swarm
        ((step++))
    fi
    
    # Final status
    echo ""
    print_success "Cleanup completed!"
    echo ""
    
    if [[ $LEAVE_SWARM != true ]]; then
        show_status
        
        echo "Next Steps:"
        echo "==========="
        if [[ $REMOVE_STACK == true ]]; then
            echo "To redeploy:"
            echo "  ./deploy-stack.sh"
        fi
    else
        echo "Docker Swarm has been completely cleaned."
        echo "To start over, run: ./deploy-swarm.sh"
    fi
    echo ""
}

# Run main function
main
