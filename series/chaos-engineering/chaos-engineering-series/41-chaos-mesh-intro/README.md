# 41 — Chaos Mesh Introduction

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Install Chaos Mesh and run your first `NetworkChaos` CR to inject pod-level network latency — a complementary alternative to LitmusChaos with a richer network chaos API.

## Why Chaos Mesh alongside LitmusChaos?

| Feature | LitmusChaos | Chaos Mesh |
|---------|------------|-----------|
| Network chaos | pod-network-latency | NetworkChaos (richer) |
| Time chaos | ❌ | TimeChaos ✅ |
| JVM chaos | ❌ | JVMChaos ✅ |
| HTTP chaos | ❌ | HTTPChaos ✅ |
| Dashboard | ChaosCenter | Built-in UI |
| CNCF status | Incubating | Incubating |

## Step 1: Install Chaos Mesh

```bash
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

kubectl create ns chaos-mesh
helm install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace=chaos-mesh \
  --version=2.6.3 \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock

kubectl get pods -n chaos-mesh
```

## Step 2: Access the Dashboard

```bash
kubectl port-forward svc/chaos-dashboard 2333:2333 -n chaos-mesh
# Open http://localhost:2333
# Default login: admin / admin
```

## Step 3: Your first NetworkChaos CR

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: target-app-latency
  namespace: default
spec:
  action: delay
  mode: all
  selector:
    namespaces: [default]
    labelSelectors:
      app: target-app
  delay:
    latency: "100ms"
    correlation: "25"
    jitter: "10ms"
  duration: "60s"
```

```bash
kubectl apply -f network-chaos.yaml

# Watch it inject
kubectl get networkchaos -n default
kubectl describe networkchaos target-app-latency -n default
```

## Step 4: Verify latency

```bash
# From inside a pod, ping target-app
kubectl exec -it debug-pod -- curl -w "%{time_total}" http://target-app:8080/health
```

## Step 5: Remove the experiment

```bash
kubectl delete networkchaos target-app-latency -n default
```

## Key Chaos Mesh CRD types

| CRD | Purpose |
|-----|---------|
| `NetworkChaos` | Delay, loss, corruption, partition |
| `PodChaos` | Pod kill, container kill, pod failure |
| `TimeChaos` | Clock skew |
| `HTTPChaos` | HTTP latency, abort, replace body |
| `IOChaos` | Filesystem fault injection |
| `JVMChaos` | JVM exception injection |
| `StressChaos` | CPU/memory stress |

---
*Part of the 100-Lesson Chaos Engineering Series.*
