# 34 — Kubernetes API Server Chaos

> **Type:** How-To  
> **Phase:** Kubernetes Chaos

## Overview

The Kubernetes API server is the single control-plane entry point. Degrading it reveals how your applications, operators, and CI/CD systems behave when `kubectl` commands slow down or fail.

## What to simulate

| Scenario | Method |
|----------|--------|
| API server high latency | Rate-limit proxy in front of apiserver |
| API server unavailable | Cordon + stop apiserver pod (local only) |
| etcd write failure | Pause etcd pod |
| Watch stream disruption | Kill and restart apiserver pod |

## Method 1: Toxiproxy in front of kube-apiserver (local kind)

For local kind clusters, proxy the apiserver through Toxiproxy:

```bash
# Get the apiserver port
kubectl cluster-info
# Kubernetes control plane is running at https://127.0.0.1:6443

# Start Toxiproxy
docker run -d -p 8474:8474 -p 6444:6444 \
  --name toxiproxy ghcr.io/shopify/toxiproxy

# Create a proxy for kube-apiserver
curl -XPOST http://localhost:8474/proxies -d '{
  "name": "kube-apiserver",
  "listen": "0.0.0.0:6444",
  "upstream": "host.docker.internal:6443"
}'

# Add 500ms latency
curl -XPOST http://localhost:8474/proxies/kube-apiserver/toxics -d '{
  "name": "apiserver-latency",
  "type": "latency",
  "attributes": {"latency": 500, "jitter": 100}
}'

# Point kubectl at the proxy
KUBECONFIG=~/.kube/config kubectl \
  --server=https://localhost:6444 get pods
```

## Method 2: Pause etcd (simulates write failures)

```bash
# Pause the etcd pod (kind control-plane node)
docker pause chaos-lab-control-plane
# Wait 30s
docker unpause chaos-lab-control-plane
```

## What to observe

```bash
# In another terminal — watch for "unable to connect" errors in operators
kubectl get events --all-namespaces -w

# Time how long operators take to recover
kubectl get pods -n litmus -w
```

## Application impact

| Component | Expected behaviour under API server latency |
|-----------|---------------------------------------------|
| Kubernetes operators | Reconcile loops slow; queues back up |
| HPA | Scale decisions delayed |
| Metrics-server | May report stale data |
| ArgoCD / Flux | Sync operations timeout |
| `kubectl` commands | Slow; may timeout |

## Insights this experiment reveals

- Do your operators have appropriate reconcile timeouts?
- Does HPA fall back gracefully when metrics are stale?
- Do your CI/CD pipelines retry on API server errors?

---
*Part of the 100-Lesson Chaos Engineering Series.*
