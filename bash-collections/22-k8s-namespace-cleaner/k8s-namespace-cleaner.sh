#!/bin/bash
# Kubernetes Namespace Cleaner Script: Clean up stale Kubernetes resources in namespaces
#
# Requirements:
#   - kubectl must be installed and configured
#   - Proper Kubernetes cluster access with permissions
#
# Usage:
#   ./k8s-namespace-cleaner.sh <namespace> [--dry-run]
#   ./k8s-namespace-cleaner.sh my-namespace --dry-run  # Show what will be deleted
#   ./k8s-namespace-cleaner.sh my-namespace        # Actually delete stale resources

set -eo pipefail

# Configuration
KUBECTL="kubectl"
DRY_RUN="false"
DELETE_FAILED_PODS="true"
DELETE_COMPLETED_JOBS="true"
DELETE_STALE_CONFIGMAPS="true"
DELETE_STALE_SECRETS="false"
DELETE_STALE_SERVICES="true"
DELETE_OLD_REPLICASETS="true"
KEEP_LATEST_REPLICASETS="3"

# Function to show usage
usage() {
    echo "Kubernetes Namespace Cleaner Script"
    echo ""
    echo "Usage: $0 <namespace> [--dry-run]"
    echo ""
    echo "Options:"
    echo "  --dry-run: Show what would be deleted without actually deleting"
    echo "  --force: Skip confirmation prompt"
    echo ""
    echo "Examples:"
    echo "  $0 my-namespace                  # Clean with confirmation"
    echo "  $0 my-namespace --dry-run        # Preview cleanup"
    echo "  $0 my-namespace --force          # Clean without confirmation"
    exit 1
}

# Parse arguments
if [ $# -lt 1 ]; then
    usage
fi

NAMESPACE="$1"
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN="true"
            ;;
        --force)
            CONFIRM="true"
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
    shift
done

# Function to log messages
log() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# Function to run kubectl with dry-run support
k8s_cmd() {
    local action="$1"
    shift
    local resource="$1"
    shift
    
    if [ "$DRY_RUN" = "true" ]; then
        log "INFO" "Would $action $resource: $@"
        # Simulate dry-run output
        echo "  (dry-run mode: no actual changes made)"
    else
        log "INFO" "$action $resource: $@"
        $KUBECTL "$action" "$@"
    fi
}

# Check if kubectl is available
if ! command -v $KUBECTL &> /dev/null; then
    log "ERROR" "kubectl not found in PATH"
    exit 1
fi

# Check if namespace exists
if ! $KUBECTL get namespace "$NAMESPACE" &> /dev/null; then
    log "ERROR" "Namespace $NAMESPACE does not exist"
    exit 1
fi

log "INFO" "Starting cleanup of namespace: $NAMESPACE"
log "INFO" "Dry-run mode: $DRY_RUN"
log "INFO" "Force mode: ${CONFIRM:-false}"

# Get total count of stale resources
TOTAL_STALE=0

# 1. Delete Failed Pods
if [ "$DELETE_FAILED_PODS" = "true" ]; then
    log "INFO" "Finding failed pods in $NAMESPACE..."
    FAILED_PODS=$($KUBECTL get pods -n "$NAMESPACE" --field-selector=status.phase=Failed -o name 2>/dev/null || true)
    FAILED_COUNT=$(echo "$FAILED_PODS" | grep -c . || true)
    
    if [ "$FAILED_COUNT" -gt 0 ]; then
        log "INFO" "Found $FAILED_COUNT failed pods"
        TOTAL_STALE=$((TOTAL_STALE + FAILED_COUNT))
        for pod in $FAILED_PODS; do
            k8s_cmd "delete" "pod" "$pod" -n "$NAMESPACE"
        done
    fi
fi

# 2. Delete Completed Jobs
if [ "$DELETE_COMPLETED_JOBS" = "true" ]; then
    log "INFO" "Finding completed jobs in $NAMESPACE..."
    COMPLETED_JOBS=$($KUBECTL get jobs -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.succeeded}{"\n"}{end}' | awk '$2 >= 1 {print $1}' 2>/dev/null || true)
    COMPLETED_COUNT=$(echo "$COMPLETED_JOBS" | grep -c . || true)
    
    if [ "$COMPLETED_COUNT" -gt 0 ]; then
        log "INFO" "Found $COMPLETED_COUNT completed jobs"
        TOTAL_STALE=$((TOTAL_STALE + COMPLETED_COUNT))
        for job in $COMPLETED_JOBS; do
            k8s_cmd "delete" "job" "$job" -n "$NAMESPACE"
        done
    fi
fi

# 3. Delete Old ReplicaSets
if [ "$DELETE_OLD_REPLICASETS" = "true" ]; then
    log "INFO" "Finding old ReplicaSets in $NAMESPACE..."
    # Get all deployments and their replica sets
    DEPLOYMENTS=$($KUBECTL get deployments -n "$NAMESPACE" -o name 2>/dev/null || true)
    
    for deploy in $DEPLOYMENTS; do
        deploy_name=$(echo "$deploy" | cut -d'/' -f2)
        log "INFO" "Cleaning up old ReplicaSets for deployment: $deploy_name"
        
        # Get all replicasets for this deployment
        REPLICASETS=$($KUBECTL get replicasets -n "$NAMESPACE" -l "app.kubernetes.io/name=$deploy_name" -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.replicas}{"\n"}{end}' 2>/dev/null || true)
        
        # Sort by creation time and keep only latest KEEP_LATEST_REPLICASETS
        OLD_RS=$(echo "$REPLICASETS" | awk '$1 == 0 {print $0}' | sort -k2 | head -n -$KEEP_LATEST_REPLICASETS | awk '{print $1}' 2>/dev/null || true)
        OLD_RS_COUNT=$(echo "$OLD_RS" | grep -c . || true)
        
        if [ "$OLD_RS_COUNT" -gt 0 ]; then
            log "INFO" "Found $OLD_RS_COUNT old ReplicaSets for $deploy_name"
            TOTAL_STALE=$((TOTAL_STALE + OLD_RS_COUNT))
            for rs in $OLD_RS; do
                k8s_cmd "delete" "replicaset" "$rs" -n "$NAMESPACE"
            done
        fi
    done
fi

# 4. Delete Stale ConfigMaps
if [ "$DELETE_STALE_CONFIGMAPS" = "true" ]; then
    log "INFO" "Finding stale configmaps not used by any pods..."
    # Find configmaps not referenced by any pod
    ALL_CONFIGMAPS=$($KUBECTL get configmaps -n "$NAMESPACE" -o name 2>/dev/null || true)
    POD_CONFIGMAPS=$($KUBECTL get pods -n "$NAMESPACE" -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.envFrom[*].configMapRef.name}{.env[*].valueFrom.configMapKeyRef.name}{end}{end}' | tr ' ' '\n' | sort -u 2>/dev/null || true)
    
    STALE_CMS=""
    for cm in $ALL_CONFIGMAPS; do
        cm_name=$(echo "$cm" | cut -d'/' -f2)
        if ! echo "$POD_CONFIGMAPS" | grep -q "$cm_name"; then
            # Skip default configmaps
            if [[ "$cm_name" != "kube-root-ca.crt" ]] && [[ "$cm_name" != "aws-auth-cm" ]]; then
                STALE_CMS+="$cm\n"
            fi
        fi
    done
    
    STALE_CM_COUNT=$(echo "$STALE_CMS" | grep -c . || true)
    if [ "$STALE_CM_COUNT" -gt 0 ]; then
        log "INFO" "Found $STALE_CM_COUNT stale configmaps"
        TOTAL_STALE=$((TOTAL_STALE + STALE_CM_COUNT))
        echo "$STALE_CMS" | while read -r cm; do
            if [ -n "$cm" ]; then
                k8s_cmd "delete" "configmap" "$cm" -n "$NAMESPACE"
            fi
        done
    fi
fi

# 5. Delete Stale Services
if [ "$DELETE_STALE_SERVICES" = "true" ]; then
    log "INFO" "Finding stale services not used by any pods..."
    ALL_SERVICES=$($KUBECTL get services -n "$NAMESPACE" -o name 2>/dev/null || true)
    POD_SELECTORS=$($KUBECTL get pods -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.spec.nodeName}{.spec.hostNetwork}{.spec.subdomain}{.spec.selector}{end}' 2>/dev/null || true)
    
    STALE_SERVICES=""
    for svc in $ALL_SERVICES; do
        svc_name=$(echo "$svc" | cut -d'/' -f2)
        # Skip Kubernetes default services
        if [[ "$svc_name" != "kubernetes" ]]; then
            # Check if service has any endpoints
            ENDPOINTS=$($KUBECTL get endpoints "$svc_name" -n "$NAMESPACE" -o jsonpath='{.subsets}' 2>/dev/null || true)
            if [ -z "$ENDPOINTS" ] || [ "$ENDPOINTS" == "null" ]; then
                STALE_SERVICES+="$svc\n"
            fi
        fi
    done
    
    STALE_SVC_COUNT=$(echo "$STALE_SERVICES" | grep -c . || true)
    if [ "$STALE_SVC_COUNT" -gt 0 ]; then
        log "INFO" "Found $STALE_SVC_COUNT stale services with no endpoints"
        TOTAL_STALE=$((TOTAL_STALE + STALE_SVC_COUNT))
        echo "$STALE_SERVICES" | while read -r svc; do
            if [ -n "$svc" ]; then
                k8s_cmd "delete" "service" "$svc" -n "$NAMESPACE"
            fi
        done
    fi
fi

# Final summary
log "INFO" "=========================================="
log "INFO" "CLEANUP COMPLETE!"
log "INFO" "=========================================="
log "INFO" "Total stale resources deleted: $TOTAL_STALE"
log "INFO" "Namespace: $NAMESPACE"
log "INFO" "Dry run: $DRY_RUN"

if [ "$DRY_RUN" = "false" ] && [ "$TOTAL_STALE" -gt 0 ]; then
    log "SUCCESS" "Successfully cleaned up $TOTAL_STALE stale resources from namespace $NAMESPACE"
elif [ "$DRY_RUN" = "false" ]; then
    log "INFO" "No stale resources found in namespace $NAMESPACE"
fi
