#!/bin/bash

# scale-swarm.sh - Scale Docker Swarm services
# Usage: ./scale-swarm.sh [SERVICE] [REPLICAS]
# Examples:
#   ./scale-swarm.sh                    # Show current status
#   ./scale-swarm.sh backend 3          # Scale backend to 3 replicas
#   ./scale-swarm.sh frontend 2         # Scale frontend to 2 replicas
#   ./scale-swarm.sh --auto             # Auto-scale based on node count

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="yolo-stack"
BACKEND_SERVICE="${STACK_NAME}_backend"
FRONTEND_SERVICE="${STACK_NAME}_frontend"

# Print header
echo ""
echo "=============================================="
echo "  Docker Swarm Service Scaling"
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

# Function to print info
print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
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
        print_error "Docker Swarm is not active. Run ./deploy-swarm.sh first"
        exit 1
    fi
}

# Check if stack exists
check_stack() {
    if ! docker stack ls 2>/dev/null | grep -q "$STACK_NAME"; then
        print_error "Stack '$STACK_NAME' not found. Run ./deploy-stack.sh first"
        exit 1
    fi
}

# Get current replica count for a service
get_replica_count() {
    local service=$1
    docker service ls --filter "name=${service}" --format "{{.Replicas}}" | cut -d'/' -f2
}

# Get running replica count for a service
get_running_count() {
    local service=$1
    docker service ls --filter "name=${service}" --format "{{.Replicas}}" | cut -d'/' -f1
}

# Get node count
get_node_count() {
    docker node ls --filter "availability=active" -q | wc -l | tr -d ' '
}

# Get available worker nodes count
get_worker_count() {
    docker node ls --filter "role=worker" --filter "availability=active" -q | wc -l | tr -d ' '
}

# Display current service status
show_status() {
    echo "Current Service Status:"
    echo "======================="
    echo ""
    
    # Get service info
    local backend_replicas=$(docker service ls --filter "name=${BACKEND_SERVICE}" --format "{{.Replicas}}" 2>/dev/null || echo "N/A")
    local frontend_replicas=$(docker service ls --filter "name=${FRONTEND_SERVICE}" --format "{{.Replicas}}" 2>/dev/null || echo "N/A")
    
    # Get node info
    local total_nodes=$(get_node_count)
    local worker_nodes=$(get_worker_count)
    local manager_nodes=$((total_nodes - worker_nodes))
    
    echo "Cluster Info:"
    echo "  Total Nodes:   $total_nodes"
    echo "  Manager Nodes: $manager_nodes"
    echo "  Worker Nodes:  $worker_nodes"
    echo ""
    
    echo "Service Replicas:"
    echo "  Backend:       $backend_replicas"
    echo "  Frontend:      $frontend_replicas"
    echo ""
    
    # Show detailed task distribution
    echo "Task Distribution:"
    echo ""
    docker stack ps "$STACK_NAME" --filter "desired-state=running" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" 2>/dev/null || print_warning "No running tasks found"
    echo ""
}

# Scale a service
scale_service() {
    local service=$1
    local replicas=$2
    local service_name=$3
    
    # Get current replica count
    local current=$(get_replica_count "$service")
    
    if [[ "$current" == "$replicas" ]]; then
        print_info "$service_name already at $replicas replicas"
        return 0
    fi
    
    echo "Scaling $service_name: $current → $replicas replicas..."
    
    if docker service scale "$service=$replicas" > /dev/null 2>&1; then
        print_success "$service_name scaled to $replicas replicas"
        
        # Wait for scaling to complete
        echo -n "Waiting for scaling to complete"
        local max_wait=30
        local waited=0
        while [[ $waited -lt $max_wait ]]; do
            local running=$(get_running_count "$service")
            if [[ "$running" == "$replicas" ]]; then
                echo ""
                print_success "All replicas are running"
                return 0
            fi
            echo -n "."
            sleep 2
            waited=$((waited + 2))
        done
        echo ""
        print_warning "Scaling in progress, check status with: docker service ps $service"
    else
        print_error "Failed to scale $service_name"
        return 1
    fi
}

# Auto-scale based on node count
auto_scale() {
    print_step "1/3" "Analyzing cluster configuration..."
    
    local total_nodes=$(get_node_count)
    local worker_nodes=$(get_worker_count)
    
    print_info "Cluster: $total_nodes total nodes, $worker_nodes worker nodes"
    
    # Backend scaling logic:
    # - If manager can run backend (no worker-only constraint): use total nodes
    # - Otherwise: use worker count only
    # - Max 1 replica per node (max_replicas_per_node: 1)
    local backend_replicas=$total_nodes
    if [[ $backend_replicas -lt 1 ]]; then
        backend_replicas=1
    fi
    
    # Frontend scaling logic:
    # - Usually runs on manager only (1 replica)
    # - Can scale up if no manager-only constraint
    local frontend_replicas=1
    
    print_info "Recommended scaling: Backend=$backend_replicas, Frontend=$frontend_replicas"
    echo ""
    
    print_step "2/3" "Scaling backend service..."
    scale_service "$BACKEND_SERVICE" "$backend_replicas" "Backend"
    echo ""
    
    print_step "3/3" "Scaling frontend service..."
    scale_service "$FRONTEND_SERVICE" "$frontend_replicas" "Frontend"
    echo ""
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [SERVICE] [REPLICAS]

Scale Docker Swarm services for the YOLO stack.

OPTIONS:
    --auto              Auto-scale based on available nodes
    --status            Show current service status (default if no args)
    -h, --help          Show this help message

ARGUMENTS:
    SERVICE             Service to scale: 'backend' or 'frontend'
    REPLICAS            Number of replicas (positive integer)

EXAMPLES:
    $0                           # Show current status
    $0 --status                  # Show current status
    $0 --auto                    # Auto-scale based on node count
    $0 backend 3                 # Scale backend to 3 replicas
    $0 frontend 2                # Scale frontend to 2 replicas

NOTES:
    - Backend has max_replicas_per_node: 1 (one replica per node)
    - Frontend is constrained to manager node by default
    - Auto-scaling respects cluster topology and constraints
    - Scaling is done with rolling update (zero downtime)

SERVICE CONSTRAINTS:
    Backend:  max 1 replica per node
    Frontend: runs on manager node (1 replica recommended)

EOF
}

# Validate replica count
validate_replicas() {
    local replicas=$1
    
    if ! [[ "$replicas" =~ ^[0-9]+$ ]] || [[ "$replicas" -lt 0 ]]; then
        print_error "Invalid replica count: $replicas"
        echo "Replica count must be a positive integer"
        exit 1
    fi
    
    if [[ "$replicas" -gt 10 ]]; then
        print_warning "Scaling to $replicas replicas is unusually high"
        read -p "Are you sure? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi
}

# Main execution
main() {
    check_docker
    check_swarm
    check_stack
    
    # Parse arguments
    if [[ $# -eq 0 ]] || [[ "$1" == "--status" ]]; then
        # Show status
        show_status
        echo "Usage: $0 [--auto | SERVICE REPLICAS]"
        echo "Run '$0 --help' for more information"
        exit 0
    fi
    
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    if [[ "$1" == "--auto" ]]; then
        # Auto-scale
        auto_scale
        echo ""
        show_status
        exit 0
    fi
    
    # Manual scaling
    if [[ $# -lt 2 ]]; then
        print_error "Missing arguments"
        echo "Usage: $0 SERVICE REPLICAS"
        echo "Run '$0 --help' for more information"
        exit 1
    fi
    
    local service_arg=$1
    local replicas=$2
    
    # Validate replica count
    validate_replicas "$replicas"
    
    # Determine which service to scale
    case "$service_arg" in
        backend|Backend|BACKEND|back)
            print_step "1/2" "Scaling backend service..."
            scale_service "$BACKEND_SERVICE" "$replicas" "Backend"
            ;;
        frontend|Frontend|FRONTEND|front|ui)
            print_step "1/2" "Scaling frontend service..."
            scale_service "$FRONTEND_SERVICE" "$replicas" "Frontend"
            ;;
        *)
            print_error "Unknown service: $service_arg"
            echo "Valid services: backend, frontend"
            exit 1
            ;;
    esac
    
    echo ""
    print_step "2/2" "Updated status"
    echo ""
    show_status
    
    echo "Scaling Tips:"
    echo "============="
    echo "• Backend max: 1 replica per node (constraint in docker-compose.swarm.yml)"
    echo "• Monitor logs: docker service logs ${STACK_NAME}_backend"
    echo "• Check tasks: docker stack ps ${STACK_NAME}"
    echo "• Rollback: docker service update --rollback ${STACK_NAME}_backend"
    echo ""
}

# Run main function
main "$@"
