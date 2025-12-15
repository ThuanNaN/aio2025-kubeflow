#!/bin/bash

# Docker Swarm Infrastructure Setup Script
# This script initializes Docker Swarm
# Run this once to set up the infrastructure, then use deploy-stack.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKER_IP="192.168.1.101"
STACK_NAME="yolo-stack"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Docker Swarm Infrastructure Setup${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Function to check if running as manager
check_swarm_status() {
    if docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo -e "${GREEN}✓ Swarm is already active${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Swarm is not initialized${NC}"
        return 1
    fi
}

# Function to initialize swarm
init_swarm() {
    echo -e "${BLUE}[1/4] Initializing Docker Swarm...${NC}"
    
    if check_swarm_status; then
        echo -e "${YELLOW}Swarm already initialized. Skipping...${NC}"
    else
        # Get the IP address of the host
        HOST_IP=$(ipconfig getifaddr en0 || ipconfig getifaddr en1 || echo "127.0.0.1")
        echo -e "${YELLOW}Host IP detected: ${HOST_IP}${NC}"
        
        docker swarm init --advertise-addr ${HOST_IP}
        echo -e "${GREEN}✓ Swarm initialized${NC}"
    fi
    
    # Get join token
    echo ""
    echo -e "${YELLOW}=================================${NC}"
    echo -e "${YELLOW}Worker Join Command:${NC}"
    echo -e "${YELLOW}=================================${NC}"
    docker swarm join-token worker
    echo -e "${YELLOW}=================================${NC}"
    echo ""
    echo -e "${BLUE}Run the above command on the worker node (192.168.1.101)${NC}"
    echo ""
    read -p "Press Enter after you've added the worker node..."
}

# Function to verify nodes
verify_nodes() {
    echo -e "${BLUE}[2/4] Verifying cluster nodes...${NC}"
    docker node ls
    echo ""
    
    WORKER_COUNT=$(docker node ls --filter role=worker -q | wc -l | tr -d ' ')
    if [ "$WORKER_COUNT" -lt 1 ]; then
        echo -e "${RED}⚠ Warning: No worker nodes found!${NC}"
        read -p "Continue anyway? (y/n): " CONTINUE
        if [ "$CONTINUE" != "y" ]; then
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Found ${WORKER_COUNT} worker node(s)${NC}"
    fi
}

# Function to show next steps
show_next_steps() {
    echo -e "${BLUE}[3/3] Setup Complete!${NC}"
    echo ""
    
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}Infrastructure Setup Complete!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo -e "${BLUE}Swarm Status:${NC}"
    docker node ls
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  Deploy the stack:"
    echo -e "     ${BLUE}./deploy-stack.sh${NC}"
    echo ""
    echo -e "${YELLOW}Useful commands:${NC}"
    echo -e "  Check nodes:   ${BLUE}docker node ls${NC}"
    echo -e "  View services: ${BLUE}docker service ls${NC}"
    echo -e "  Leave swarm:   ${BLUE}docker swarm leave --force${NC}"
    echo ""
}

# Main execution
main() {
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi
    
    init_swarm
    verify_nodes
    show_next_steps
}

# Run main function
main
