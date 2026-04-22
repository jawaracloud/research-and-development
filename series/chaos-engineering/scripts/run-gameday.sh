#!/usr/bin/env bash
# run-gameday.sh — Execute the full GameDay ChaosWorkflow against the target cluster
set -euo pipefail

NAMESPACE="${NAMESPACE:-litmus}"
WORKFLOW_FILE="${1:-../95-gameday-execution/gameday-workflow.yaml}"

echo "==> Applying GameDay workflow: $WORKFLOW_FILE"
kubectl apply -f "$WORKFLOW_FILE" -n "$NAMESPACE"

echo "==> Watching workflow status..."
kubectl get workflow -n "$NAMESPACE" -w
