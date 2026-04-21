#!/bin/bash
# Kubernetes Pod Restart Script: Gracefully restart Kubernetes pods with selectors
#
# Requirements:
#   - kubectl must be installed and configured
#   - Proper Kubernetes cluster access
#
# Usage:
#   ./k8s-pod-restart.sh <deployment-name> <namespace> [container-name]
#   ./k8s-pod-restart.sh my-app default
#   ./k8s-pod-restart.sh my-app default my-container

set -eo pipefail

# Configuration
KUBECTL="kubectl"
GRACE_PERIOD_SECONDS="30"

# Function to show usage
usage() {
    echo "Kubernetes Pod Restart Script"
    echo ""
    echo "Usage: $0 <resource-type/name> <namespace> [container-name]"
    echo ""
    echo "Examples:"
    echo "  $0 deployment/my-app default"
    echo "  $0 statefulset/db-postgres default"
    echo "  $0 pod/my-pod-abc123 kube-system"
    echo "  $0 deployment/my-app default my-container"
    echo ""
    echo "Resource types: deployment, statefulset, daemonset, pod"
    exit 1
}

# Check for required arguments
if [ $# -lt 2 ]; then
    usage
fi

RESOURCE_TARGET="$1"
NAMESPACE="$2"
CONTAINER_NAME="$3"

# Validate resource format
if [[ ! "$RESOURCE_TARGET" =~ ^(deployment|statefulset|daemonset|pod)/ ]]; then
    echo "Error: Resource must be in format type/name (e.g. deployment/my-app)"
    exit 1
fi

RESOURCE_TYPE=$(echo "$RESOURCE_TARGET" | cut -d'/' -f1)
RESOURCE_NAME=$(echo "$RESOURCE_TARGET" | cut -d'/' -f2)

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check if kubectl is available
if ! command -v $KUBECTL &> /dev/null; then
    echo "Error: kubectl not found in PATH"
    exit 1
fi

# Check if namespace exists
if ! $KUBECTL get namespace "$NAMESPACE" &> /dev/null; then
    echo "Error: Namespace $NAMESPACE does not exist"
    exit 1
fi

# Get current replicas
log "Checking current replicas for $RESOURCE_TARGET in $NAMESPACE"
CURRENT_REPLICAS=$($KUBECTL get $RESOURCE_TYPE "$RESOURCE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)

if [ -z "$CURRENT_REPLICAS" ] && [ "$RESOURCE_TYPE" != "pod" ]; then
    echo "Error: Could not get replicas for $RESOURCE_TARGET"
    exit 1
fi

log "Found $CURRENT_REPLICAS replicas"

# Confirm restart
read -p "Are you sure you want to restart $RESOURCE_TYPE $RESOURCE_NAME in $NAMESPACE? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Restart cancelled by user"
    exit 0
fi

# Perform restart
log "Restarting $RESOURCE_TYPE $RESOURCE_NAME in $NAMESPACE..."

case $RESOURCE_TYPE in
    deployment|statefulset|daemonset)
        # For workloads: Use rollout restart
        if [ -n "$CONTAINER_NAME" ]; then
            log "Restarting with specific container: $CONTAINER_NAME"
            $KUBECTL rollout restart $RESOURCE_TYPE "$RESOURCE_NAME" -n "$NAMESPACE" --container="$CONTAINER_NAME"
        else
            $KUBECTL rollout restart $RESOURCE_TYPE "$RESOURCE_NAME" -n "$NAMESPACE"
        fi
        
        # Wait for rollout to complete
        log "Waiting for rollout to complete..."
        $KUBECTL rollout status $RESOURCE_TYPE "$RESOURCE_NAME" -n "$NAMESPACE" --timeout=5m
        ;;
    
    pod)
        # For individual pods: Delete with grace period
        if [ -n "$CONTAINER_NAME" ]; then
            log "Executing command in pod: $CONTAINER_NAME"
            $KUBECTL exec -n "$NAMESPACE" "$RESOURCE_NAME" -c "$CONTAINER_NAME" -- /bin/sh -c "pkill -SIGTERM -1"
            sleep $GRACE_PERIOD_SECONDS
            $KUBECTL delete pod "$RESOURCE_NAME" -n "$NAMESPACE" --grace-period=$GRACE_PERIOD_SECONDS
        else
            $KUBECTL delete pod "$RESOURCE_NAME" -n "$NAMESPACE" --grace-period=$GRACE_PERIOD_SECONDS
        fi
        ;;
    
    *)
        echo "Unsupported resource type: $RESOURCE_TYPE"
        exit 1
        ;;
esac

# Show status
log ""
log "Restart completed! Status:"
$KUBECTL get $RESOURCE_TYPE "$RESOURCE_NAME" -n "$NAMESPACE" -o wide

log ""
log "To monitor progress:"
log "  $KUBECTL get pods -n $NAMESPACE -l $($KUBECTL get $RESOURCE_TYPE $RESOURCE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.matchLabels}' | jq -r 'to_entries[] | "\(.key)=\(.value)"' | head -1 | sed 's/=/="/;s/$/"/')"
log ""
log "To view logs:"
log "  $KUBECTL logs -f -n $NAMESPACE $($KUBECTL get pods -n $NAMESPACE -l app=$RESOURCE_NAME -o jsonpath='{.items[0].metadata.name}')"
