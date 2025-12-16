#!/bin/bash

# Simple wrk benchmark script for YOLO Backend API

# Default values
SERVICE_PORT=30987

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            SERVICE_PORT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -p, --port PORT    Service port (default: 30987)"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

KUBE_IP=$(minikube ip)
echo "Running wrk benchmark against YOLO Backend API at ${KUBE_IP}:${SERVICE_PORT}"

wrk -t12 -c400 -d600s http://${KUBE_IP}:${SERVICE_PORT}/health