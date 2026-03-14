# 20 — NATS on Docker & Kubernetes

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

Deploy a production-ready NATS JetStream cluster on Kubernetes using the official Helm chart, with persistent storage and monitoring enabled.

## Docker single-node (development)

```bash
# Single node with JetStream and monitoring
docker run -d --name nats \
  -p 4222:4222 \
  -p 8222:8222 \
  nats:2.10-alpine -js -m 8222

# Verify
nats server info --server nats://localhost:4222
```

## Docker Compose cluster (this series lab)

```bash
docker compose up -d nats-1 nats-2 nats-3
nats server ls --server nats://localhost:4222
# nats-1  nats-2  nats-3
```

## Kubernetes Deployment (Helm)

```bash
# Add NATS Helm repo
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm repo update

# Install 3-node NATS cluster with JetStream
helm install nats nats/nats \
  --namespace nats --create-namespace \
  --set config.cluster.enabled=true \
  --set config.cluster.replicas=3 \
  --set config.jetstream.enabled=true \
  --set config.jetstream.fileStore.pvc.size=10Gi \
  --set config.monitor.enabled=true
```

## Helm values file (production)

`nats-values.yaml`:

```yaml
config:
  cluster:
    enabled: true
    replicas: 3
    name: nats-cluster

  jetstream:
    enabled: true
    fileStore:
      pvc:
        size: 20Gi
        storageClassName: standard
    maxMemoryStore: 2Gi
    maxFileStore: 20Gi

  monitor:
    enabled: true
    port: 8222

natsBox:
  enabled: true   # deploys a debug pod with nats CLI pre-installed

podDisruptionBudget:
  enabled: true
  minAvailable: 2   # always keep 2/3 pods alive

resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

```bash
helm install nats nats/nats -n nats -f nats-values.yaml
```

## Verify Kubernetes deployment

```bash
kubectl get pods -n nats
# nats-0   Running
# nats-1   Running
# nats-2   Running
# nats-box Running  ← debug pod

# Connect via nats-box
kubectl exec -it -n nats deploy/nats-box -- sh
nats server info
nats server ls
```

## Port-forward for local access

```bash
kubectl port-forward -n nats svc/nats 4222:4222 8222:8222
nats pub test "hello" --server nats://localhost:4222
```

---
*Part of the 100-Lesson NATS Series.*
