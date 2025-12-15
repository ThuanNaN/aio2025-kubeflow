#!/bin/bash

# Stress test runner for YOLO Backend API
# Supports multiple environments and test profiles

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.yaml"
RESULTS_DIR="${SCRIPT_DIR}/results"

# Functions
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${BLUE}$1${NC}"; }

# Parse config file
get_env_url() {
    local env=$1
    python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['environments']['$env']['url'])"
}

get_profile_config() {
    local profile=$1
    local key=$2
    python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG_FILE'))['test_profiles']['$profile']['$key'])"
}

# Check if API is available
check_api() {
    local url=$1
    print_info "Checking if API is available at ${url}..."
    if curl -s -f "${url}/health" > /dev/null 2>&1; then
        print_info "✓ API is responding"
        return 0
    else
        print_warning "✗ API is not responding at ${url}"
        print_warning "The test will proceed, but may fail if the API is not available"
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        exit 1
    fi
    
    if ! python3 -c "import locust" 2>/dev/null; then
        print_warning "Dependencies not installed. Installing..."
        pip install -r "${SCRIPT_DIR}/requirements.txt"
    fi
}

# Run async benchmark
run_async_benchmark() {
    local env=$1
    local profile=$2
    local url=$3
    
    if [ -n "$url" ]; then
        python3 "${SCRIPT_DIR}/benchmark_async.py" --url "$url" ${profile:+--profile "$profile"}
    elif [ -n "$env" ]; then
        python3 "${SCRIPT_DIR}/benchmark_async.py" --env "$env" ${profile:+--profile "$profile"}
    else
        python3 "${SCRIPT_DIR}/benchmark_async.py" --env local
    fi
}

# Run locust web UI
run_locust_web() {
    local url=$1
    print_info "Starting Locust web UI..."
    print_info "Open http://localhost:8089 in your browser"
    locust -f "${SCRIPT_DIR}/stress_test.py" \
        --host="${url}" \
        --web-host=0.0.0.0 \
        --web-port=8089
}

# Run locust headless
run_locust_headless() {
    local url=$1
    local profile=$2
    
    if [ -n "$profile" ]; then
        local users=$(get_profile_config "$profile" "users")
        local spawn_rate=$(get_profile_config "$profile" "spawn_rate")
        local duration=$(get_profile_config "$profile" "duration")
        
        print_info "Running profile: $profile"
        print_info "Users: $users, Spawn rate: $spawn_rate, Duration: $duration"
        
        mkdir -p "${RESULTS_DIR}"
        locust -f "${SCRIPT_DIR}/stress_test.py" \
            --host="${url}" \
            --headless \
            -u "$users" \
            -r "$spawn_rate" \
            -t "$duration" \
            --html="${RESULTS_DIR}/${profile}_report_$(date +%Y%m%d_%H%M%S).html" \
            --csv="${RESULTS_DIR}/${profile}_$(date +%Y%m%d_%H%M%S)"
    else
        print_error "Profile is required for headless mode"
        exit 1
    fi
}

# List available environments and profiles
list_options() {
    print_header "\n=== Available Environments ==="
    python3 -c "
import yaml
config = yaml.safe_load(open('$CONFIG_FILE'))
for env, details in config['environments'].items():
    print(f\"  {env:15} - {details['description']} ({details['url']})\")
"
    
    print_header "\n=== Available Test Profiles ==="
    python3 -c "
import yaml
config = yaml.safe_load(open('$CONFIG_FILE'))
for profile, details in config['test_profiles'].items():
    print(f\"  {profile:15} - {details['description']}\")
    print(f\"                    Users: {details['users']}, Spawn rate: {details['spawn_rate']}, Duration: {details['duration']}\")
"
    echo
}

# Show usage
show_usage() {
    cat << EOF
${BLUE}YOLO Backend API - Stress Test Runner${NC}

Usage: $0 [OPTIONS]

Options:
    -e, --env <env>          Environment to test (local, docker, kubernetes, staging, production)
    -p, --profile <profile>  Test profile (smoke, quick, standard, load, spike, endurance, stress)
    -u, --url <url>          Custom API URL (overrides --env)
    -m, --mode <mode>        Test mode: async (default), web, headless
    -l, --list               List available environments and profiles
    -h, --help               Show this help message

Examples:
    # Quick async benchmark on local environment
    $0 --env local --profile quick

    # Async benchmark with custom URL
    $0 --url http://localhost:8000 --profile standard

    # Locust web UI for interactive testing
    $0 --env kubernetes --mode web

    # Locust headless with profile
    $0 --env staging --profile load --mode headless

    # List available options
    $0 --list

EOF
}

# Main script
main() {
    # Default values
    ENV=""
    PROFILE=""
    URL=""
    MODE="async"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                ENV="$2"
                shift 2
                ;;
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            -u|--url)
                URL="$2"
                shift 2
                ;;
            -m|--mode)
                MODE="$2"
                shift 2
                ;;
            -l|--list)
                list_options
                exit 0
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check dependencies
    check_dependencies
    
    # Determine URL
    if [ -n "$URL" ]; then
        TARGET_URL="$URL"
    elif [ -n "$ENV" ]; then
        TARGET_URL=$(get_env_url "$ENV")
    else
        ENV="local"
        TARGET_URL=$(get_env_url "local")
    fi
    
    # Check API availability
    check_api "$TARGET_URL"
    
    # Create results directory
    mkdir -p "${RESULTS_DIR}"
    
    # Run test based on mode
    case "$MODE" in
        async)
            print_info "Running async benchmark..."
            run_async_benchmark "$ENV" "$PROFILE" "$URL"
            ;;
        web)
            run_locust_web "$TARGET_URL"
            ;;
        headless)
            run_locust_headless "$TARGET_URL" "$PROFILE"
            ;;
        *)
            print_error "Unknown mode: $MODE"
            show_usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
