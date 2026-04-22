# 38 — PVC Deletion

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

An experiment that deletes a PersistentVolumeClaim (PVC) used by a StatefulSet, validating data durability and testing the recovery procedure for stateful workloads.

**Hypothesis**: When a PVC is deleted while a StatefulSet pod is running, the StatefulSet pod is evicted, the PVC is dynamically re-provisioned, and the application recovers with no permanent data loss (assuming the storage backend has redundancy).

## Prerequisites

- A StatefulSet with a `volumeClaimTemplate` (e.g., PostgreSQL or a stateful version of target-app)
- A storage provisioner (in kind: `rancher.io/local-path`)

## Step 1: Deploy a stateful app

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: stateful-app
  namespace: default
spec:
  serviceName: stateful-app
  replicas: 1
  selector:
    matchLabels:
      app: stateful-app
  template:
    metadata:
      labels:
        app: stateful-app
    spec:
      containers:
        - name: app
          image: postgres:16-alpine
          env:
            - name: POSTGRES_PASSWORD
              value: chaos123
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
```

## Step 2: Install and apply pvc-delete experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/pvc-delete \
  -n litmus
```

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: pvc-delete-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=stateful-app"
    appkind: statefulset
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pvc-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: PVC_LABEL
              value: "app=stateful-app"
            - name: FORCE
              value: "false"
```

## Step 3: Observe recovery

```bash
kubectl get pvc -n default -w
# data-stateful-app-0  Bound    ...
# data-stateful-app-0  Terminating
# data-stateful-app-0  Bound    ... (re-provisioned)

kubectl get pods -n default -w
```

## Reclaim Policy Implications

| Reclaim Policy | PV after PVC deletion |
|---------------|----------------------|
| `Retain` | PV data preserved; manual re-attach required |
| `Recycle` | PV wiped and made available (deprecated) |
| `Delete` | PV and underlying storage permanently deleted |

---
*Part of the 100-Lesson Chaos Engineering Series.*
