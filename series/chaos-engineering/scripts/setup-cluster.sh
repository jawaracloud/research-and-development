#!/usr/bin/env bash
# setup-cluster.sh — Bootstrap a local kind cluster with LitmusChaos + Chaos Mesh
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-chaos-lab}"
LITMUS_VERSION="${LITMUS_VERSION:-3.9.0}"
CHAOS_MESH_VERSION="${CHAOS_MESH_VERSION:-2.6.3}"

echo "==> Creating kind cluster: $CLUSTER_NAME"
kind create cluster --name "$CLUSTER_NAME" --config "$(dirname "$0")/kind-config.yaml"

echo "==> Switching kubectl context"
kubectl cluster-info --context "kind-$CLUSTER_NAME"

echo "==> Installing LitmusChaos v${LITMUS_VERSION}"
kubectl apply -f \
  "https://litmuschaos.github.io/litmus/litmus-operator-v${LITMUS_VERSION}.yaml"
kubectl wait --for=condition=Ready pods -l app=litmus -n litmus --timeout=120s

echo "==> Installing Chaos Mesh v${CHAOS_MESH_VERSION}"
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update
kubectl create ns chaos-mesh --dry-run=client -o yaml | kubectl apply -f -
helm install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace=chaos-mesh \
  --version="${CHAOS_MESH_VERSION}" \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock

echo "==> Installing Prometheus + Grafana (kube-prometheus-stack)"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create ns monitoring --dry-run=client -o yaml | kubectl apply -f -
helm install kube-prom prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=chaos123

echo ""
echo "✅  Cluster '$CLUSTER_NAME' is ready!"
echo "   Grafana: kubectl port-forward svc/kube-prom-grafana 3000:80 -n monitoring"
echo "   LitmusChaos: kubectl port-forward svc/litmus-frontend-service 9091:9091 -n litmus"
