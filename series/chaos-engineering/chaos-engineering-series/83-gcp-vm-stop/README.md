# 83 — GCP VM Stop

> **Type:** Tutorial  
> **Phase:** Advanced Topics & GameDay

## What you're building

Use LitmusChaos's GCP experiment to stop a Compute Engine VM instance, validating compute resilience on GCP-hosted Kubernetes nodes (GKE).

> **Prerequisites:** GCP project, service account with `compute.instances.stop` permission, Workload Identity or key secret.

## Step 1: Create GCP key secret

```bash
kubectl create secret generic gcp-key \
  --from-file=key.json=/path/to/service-account-key.json \
  -n litmus
```

## Step 2: Install the experiment

```bash
kubectl apply -f \
  "https://hub.litmuschaos.io/api/chaos/3.9.0?item=gcp/gcp-vm-instance-stop" \
  -n litmus
```

## Step 3: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: gcp-vm-stop-engine
  namespace: litmus
spec:
  chaosServiceAccount: litmus-admin
  experiments:
    - name: gcp-vm-instance-stop
      spec:
        components:
          env:
            - name: VM_INSTANCE_NAMES
              value: "gke-my-cluster-default-pool-abc123"
            - name: GCP_PROJECT_ID
              value: "my-gcp-project"
            - name: ZONES
              value: "asia-southeast1-b"
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: MANAGED_INSTANCE_GROUP
              value: "true"      # GKE uses MIGs — restarts automatically
          secrets:
            - name: gcp-key
              mountPath: /tmp/
        probe:
          - name: service-health
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "10s"
              retry: 5
              interval: "5s"
            httpProbe/inputs:
              url: "https://my-app.example.com/health"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## Step 4: Monitor with gcloud CLI

```bash
# Watch instance status
gcloud compute instances describe gke-my-cluster-default-pool-abc123 \
  --zone asia-southeast1-b \
  --format="get(status)"
# STOPPING
# TERMINATED
# STAGING  (restarting)
# RUNNING

# Watch GKE node readiness
kubectl get nodes -w
```

## GKE Autopilot vs Standard

| Cluster | VM stop behaviour |
|---------|-----------------|
| GKE Standard | Node leaves cluster; MIG replaces |
| GKE Autopilot | Google manages node pool; auto-replaces |

## Spot/Preemptible simulation

GCP Preemptible VMs are stopped automatically by Google with a 30-second ACPI signal. This experiment simulates that:

```yaml
env:
  - name: INSTANCE_STOP_TYPE
    value: "PREEMPTIBLE"   # simulates preemption, not graceful stop
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
