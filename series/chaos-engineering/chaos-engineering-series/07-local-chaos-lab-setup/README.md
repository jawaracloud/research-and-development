# 07 — Local Chaos Lab Setup

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

A fully local chaos lab with:
- A `kind` Kubernetes cluster
- LitmusChaos operator + ChaosCenter
- Chaos Mesh + dashboard
- Prometheus + Grafana for observability

## Prerequisites

Verify your environment first:

```bash
bash scripts/verify-env.sh
```

## Step 1: Create the kind cluster

```bash
# From the series root
bash scripts/setup-cluster.sh
```

This creates a `chaos-lab` kind cluster and installs LitmusChaos + Chaos Mesh + Prometheus.

### Manual kind cluster (alternative)

```bash
cat <<EOF | kind create cluster --name chaos-lab --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF
```

## Step 2: Verify cluster health

```bash
kubectl get nodes
# NAME                      STATUS   ROLES           AGE
# chaos-lab-control-plane   Ready    control-plane   2m
# chaos-lab-worker          Ready    <none>          2m
# chaos-lab-worker2         Ready    <none>          2m

kubectl get pods -n litmus
# NAME                                    READY   STATUS    RESTARTS
# chaos-operator-ce-...                   1/1     Running   0
# litmus-frontend-...                     1/1     Running   0
```

## Step 3: Verify LitmusChaos

```bash
kubectl get chaosexperiment -n litmus | head -20
```

## Step 4: Access Grafana

```bash
kubectl port-forward svc/kube-prom-grafana 3000:80 -n monitoring
# Open: http://localhost:3000  (admin / chaos123)
```

## Step 5: Access Chaos Mesh dashboard

```bash
kubectl port-forward svc/chaos-dashboard 2333:2333 -n chaos-mesh
# Open: http://localhost:2333
```

## Expected output

```
NAME                      STATUS   ROLES
chaos-lab-control-plane   Ready    control-plane
chaos-lab-worker          Ready    <none>
chaos-lab-worker2         Ready    <none>

✅ LitmusChaos: Running
✅ Chaos Mesh:  Running
✅ Prometheus:  Running
✅ Grafana:     Running
```

## Cleanup

```bash
bash scripts/teardown.sh
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
