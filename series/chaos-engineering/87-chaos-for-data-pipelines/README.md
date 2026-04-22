# 87 — Chaos for Data Pipelines

> **Type:** Tutorial  
> **Phase:** Advanced Topics & GameDay

## What you're building

Apply chaos to a data pipeline (Kafka or NATS-based) to validate message delivery guarantees, consumer group recovery, and backpressure handling.

## Pipeline Architecture

```
Producer (target-app)
    └── NATS JetStream topic: events
        └── Consumer (processor-svc)
            └── PostgreSQL (sink)
```

## Step 1: Deploy NATS with JetStream

```bash
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm install nats nats/nats \
  --set config.jetstream.enabled=true \
  --set config.cluster.enabled=true \
  --set replicas=3
```

## Step 2: Chaos experiments for data pipelines

### 2a. Kill consumer pods

```yaml
# Simulates: consumer crash — will messages be reprocessed?
spec:
  appinfo:
    applabel: "app=processor-svc"
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
```

**Hypothesis**: When the consumer pod is killed, in-flight messages are redelivered by NATS after the `MaxDeliverAttempts` timeout, and no messages are permanently lost.

### 2b. Kill NATS broker pods

```yaml
spec:
  appinfo:
    applabel: "app.kubernetes.io/name=nats"
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: PODS_AFFECTED_PERC
              value: "33"   # 1 of 3 cluster nodes
```

**Hypothesis**: With NATS clustering (3 nodes, raft quorum = 2), killing 1 node causes a brief leader re-election but no message loss.

## Step 3: Validate message counts

```go
// Before chaos: record inflight count
inflight, _ := js.StreamInfo("events")
beforeSeq := inflight.State.LastSeq

// Apply chaos...

// After recovery: ensure no sequence gaps
afterInfo, _ := js.StreamInfo("events")
// afterInfo.State.NumDeleted == 0 means no dropped messages
```

## Step 4: Consumer group recovery time

```bash
# Watch consumer lag during and after chaos
nats consumer report events processor-group
# Subject      Consumers  State     Unprocessed  Redelivered
# events       1          Running   0            14   ← replayed on restart
```

## What this experiment reveals

- Is the consumer group configured with `AckWait` set correctly?
- Are messages idempotent (safe to reprocess)?
- Does the producer back-pressure correctly when NATS is slow?

---
*Part of the 100-Lesson Chaos Engineering Series.*
