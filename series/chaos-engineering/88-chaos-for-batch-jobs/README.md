# 88 — Chaos for Batch Jobs

> **Type:** Tutorial  
> **Phase:** Advanced Topics & GameDay

## What you're building

Inject chaos into Kubernetes batch jobs (Jobs and CronJobs), validating restart policies, idempotency, and checkpoint resumption.

**Hypothesis**: When a running batch Job pod is killed, the Job creates a new pod and completes successfully with the correct output — no data corruption, no duplicate processing.

## Step 1: Sample batch job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-export
  namespace: default
spec:
  backoffLimit: 3         # retry up to 3 times
  completions: 1
  template:
    metadata:
      labels:
        app: data-export
      annotations:
        litmuschaos.io/chaos: "true"
    spec:
      restartPolicy: OnFailure  # retry on pod failure
      containers:
        - name: exporter
          image: golang:1.23-alpine
          env:
            - name: CHECKPOINT_FILE
              value: "/data/checkpoint"
          command: [sh, -c]
          args:
            - |
              # Resume from checkpoint if exists
              START=0
              [ -f "$CHECKPOINT_FILE" ] && START=$(cat "$CHECKPOINT_FILE")
              echo "Starting from offset: $START"

              for i in $(seq $START 1000); do
                echo "$i" > "$CHECKPOINT_FILE"   # save progress
                sleep 0.01                        # simulate work
              done
              echo "Batch complete"
          volumeMounts:
            - name: checkpoint
              mountPath: /data
      volumes:
        - name: checkpoint
          persistentVolumeClaim:
            claimName: batch-checkpoint-pvc
```

## Step 2: Apply chaos during batch job

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: batch-job-kill
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=data-export"
    appkind: job             # target a Job kind
  chaosServiceAccount: litmus-admin
  annotationCheck: "true"
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "10"
            - name: FORCE
              value: "true"
```

## Step 3: Observe restart and resume

```bash
kubectl get pods -n default -w
# data-export-abc   Running   0
# data-export-abc   Failed    0   ← chaos kill
# data-export-def   Running   0   ← new pod, resumes from checkpoint

kubectl logs data-export-def
# Starting from offset: 342   ← resumed, not from 0
# ...
# Batch complete              ← finished successfully
```

## Key resilience properties

| Property | Implementation |
|----------|---------------|
| Checkpointing | Write last completed offset to PVC |
| Idempotency | Processing the same record twice is safe |
| Retry limit | `backoffLimit: 3` prevents infinite loops |
| Deduplication | Output sink checks for duplicates |

---
*Part of the 100-Lesson Chaos Engineering Series.*
