#!/bin/bash

# Deploy Stack Script
# This script deploys the YOLO stack using images from GitHub Container Registry (GHCR)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="yolo-stack"
COMPOSE_FILE="docker-compose.swarm.yml"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Deploy Stack from GHCR${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if swarm is active
check_swarm() {
    echo -e "${BLUE}[1/2] Checking Docker Swarm status...${NC}"
    
    if docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo -e "${GREEN}✓ Swarm is active${NC}"
    else
        echo -e "${RED}✗ Docker Swarm is not initialized${NC}"
        echo -e "${YELLOW}Run './deploy-swarm.sh' first to initialize swarm${NC}"
        exit 1
    fi
}

# Deploy stack
deploy_stack() {
    echo -e "${BLUE}[2/2] Deploying stack from GHCR...${NC}"
    
    echo -e "${YELLOW}Deploying stack: ${STACK_NAME}${NC}"
    echo -e "${YELLOW}Images from: ghcr.io/thuannan/aio2025-kubeflow/*${NC}"
    
    docker stack deploy -c ${COMPOSE_FILE} ${STACK_NAME}
    
    echo -e "${GREEN}✓ Stack deployment initiated${NC}"
}

# Show status
show_status() {
    echo ""
    echo -e "${BLUE}Checking deployment status...${NC}"
    echo ""
    
    echo -e "${YELLOW}Waiting for services to start...${NC}"
    sleep 5
    
    echo ""
    echo -e "${YELLOW}Services:${NC}"
    docker stack services ${STACK_NAME}
    
    echo ""
    echo -e "${YELLOW}Running tasks:${NC}"
    docker stack ps ${STACK_NAME} --filter "desired-state=running"
    
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}Stack Deployment Complete!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo -e "${BLUE}Access points:${NC}"
    echo -e "  Frontend: ${GREEN}http://localhost:7860${NC}"
    echo -e "  Backend:  ${GREEN}http://localhost:8000${NC}"
    echo ""
    echo -e "${YELLOW}Useful commands:${NC}"
    echo -e "  View services: ${BLUE}docker stack services ${STACK_NAME}${NC}"
    echo -e "  View tasks:    ${BLUE}docker stack ps ${STACK_NAME} --filter \"desired-state=running\"${NC}"
    echo -e "  View logs:     ${BLUE}docker service logs ${STACK_NAME}_backend${NC}"
    echo -e "  Scale service: ${BLUE}docker service scale ${STACK_NAME}_backend=3${NC}"
    echo -e "  Update stack:  ${BLUE}./deploy-stack.sh${NC}"
    echo -e "  Remove stack:  ${BLUE}docker stack rm ${STACK_NAME}${NC}"
    echo ""
}

# Main execution
main() {
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi
    
    # Check if compose file exists
    if [ ! -f "${COMPOSE_FILE}" ]; then
        echo -e "${RED}Error: ${COMPOSE_FILE} not found${NC}"
        exit 1
    fi
    
    check_swarm
    deploy_stack
    show_status
}

# Run main function
main
