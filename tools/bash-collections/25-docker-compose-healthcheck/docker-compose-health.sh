#!/bin/bash
# Docker Compose Healthcheck: Monitor the health status of Docker Compose services
#
# Requirements:
#   - Docker and Docker Compose installed
#   - Script must be run in the directory containing docker-compose.yaml
#
# Usage:
#   ./docker-compose-health.sh [timeout_seconds]
#   ./docker-compose-health.sh 60  # Wait up to 60 seconds for services to be healthy

set -eo pipefail

# Configuration
COMPOSE_FILE="docker-compose.yaml"
TIMEOUT_SECONDS=${1:-30} # Default timeout to 30 seconds

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if docker-compose.yaml exists
if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "No docker-compose.yaml found in current directory. Please run the script from the Docker Compose project root."
fi

log_info "Checking health of Docker Compose services defined in $COMPOSE_FILE (timeout: ${TIMEOUT_SECONDS}s)"

# Check if Docker is running
if ! docker info &>/dev/null; then
    log_error "Docker is not running. Please start Docker service."
fi

start_time=$(date +%s)

# Loop until all services are healthy or timeout is reached
while true; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    
    if [ "$elapsed_time" -ge "$TIMEOUT_SECONDS" ]; then
        log_error "Timeout reached. Not all services are healthy after ${TIMEOUT_SECONDS} seconds."
    fi
    
    # Get service health status
    HEALTH_STATUS=$(docker compose ps --services --filter health.status=healthy --format json 2>/dev/null || true)
    TOTAL_SERVICES=$(docker compose ps --services --format json 2>/dev/null | jq -r 'length')
    HEALTHY_SERVICES=$(echo "$HEALTH_STATUS" | jq -r 'length')
    
    # Get unhealthy services (for detailed error reporting)
    UNHEALTHY_SERVICES=$(docker compose ps --services --filter health.status=unhealthy --format json 2>/dev/null || true)
    UNHEALTHY_COUNT=$(echo "$UNHEALTHY_SERVICES" | jq -r 'length')
    
    if [ -z "$TOTAL_SERVICES" ] || [ "$TOTAL_SERVICES" -eq 0 ]; then
        log_error "No services found in docker-compose.yaml. Ensure services are defined."
    fi

    if [ "$HEALTHY_SERVICES" -eq "$TOTAL_SERVICES" ]; then
        log_success "All ${TOTAL_SERVICES} services are healthy!"
        break
    else
        log_warn "${HEALTHY_SERVICES}/${TOTAL_SERVICES} services healthy. Waiting for others... Elapsed: ${elapsed_time}s"
        if [ "$UNHEALTHY_COUNT" -gt 0 ]; then
            log_warn "Unhealthy services:"
            echo "$UNHEALTHY_SERVICES" | jq -r '.[] | "  - \(.Service)"
        fi
        sleep 5
    fi
done

exit 0
