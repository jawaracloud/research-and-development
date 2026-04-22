# 85 — Stateful Chaos

> **Type:** Tutorial  
> **Phase:** Advanced Topics & GameDay

## What you're building

Inject chaos into a **StatefulSet** workload (e.g., PostgreSQL, Redis, Kafka), validating state persistence, leader election behaviour, and automated recovery from pod disruption.

## Why StatefulSets need special attention

Unlike Deployments, StatefulSets:
- Have **stable network identities** (`kafka-0`, `kafka-1`)
- Have **ordered start/stop** (pod N must be ready before N+1)
- Have **per-pod PVCs** (losing pod-1 doesn't affect pod-0's data)

## Step 1: Deploy a Redis StatefulSet (3-node cluster)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
  namespace: default
spec:
  serviceName: redis
  replicas: 3
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
      annotations:
        litmuschaos.io/chaos: "true"
    spec:
      containers:
        - name: redis
          image: redis:7-alpine
          ports:
            - containerPort: 6379
          args: ["--cluster-enabled", "yes", "--cluster-config-file", "nodes.conf"]
          volumeMounts:
            - name: data
              mountPath: /data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
```

## Step 2: ChaosEngine targeting StatefulSet

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: redis-pod-delete
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=redis"
    appkind: statefulset     # <-- key difference
  chaosServiceAccount: litmus-admin
  annotationCheck: "true"
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: PODS_AFFECTED_PERC
              value: "33"   # 1 of 3 pods
            - name: CHAOS_INTERVAL
              value: "10"
        probe:
          - name: data-integrity
            type: cmdProbe
            mode: EOT
            runProperties:
              probeTimeout: "30s"
              retry: 3
              interval: "5s"
            cmdProbe/inputs:
              command: |
                redis-cli -h redis-0.redis.default.svc.cluster.local ping
              comparator:
                type: string
                criteria: "=="
                value: "PONG"
              source: inline
```

## Step 3: Observe StatefulSet ordering

```bash
kubectl get pods -n default -l app=redis -w
# redis-0  Running
# redis-1  Running  
# redis-2  Running
# redis-1  Terminating   ← chosen for deletion
# redis-1  Pending       ← waiting for PVC to re-attach
# redis-1  Running       ← recovered with same identity and data
```

## Data durability check

```bash
# Before chaos: set a key
redis-cli -h redis-0.redis.default.svc.cluster.local SET chaos-key "hello"

# After pod-1 restart: key should still exist via cluster
redis-cli -h redis-0.redis.default.svc.cluster.local GET chaos-key
# "hello"  ✅ data persisted
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
