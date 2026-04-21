# 84 — Multi-Cluster Chaos

> **Type:** Tutorial  
> **Phase:** Advanced Topics & GameDay

## What you're building

Run coordinated chaos across **two Kubernetes clusters** simultaneously, simulating region-level failures and testing cross-cluster failover, DNS-based traffic routing, and geo-redundancy.

## Architecture

```
Region A (Primary)           Region B (DR / Secondary)
┌─────────────────────┐     ┌─────────────────────┐
│  cluster-a           │     │  cluster-b           │
│  target-app:3        │     │  target-app:3        │
│  postgres            │     │  postgres (standby)  │
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
     Global Load Balancer (DNS)
```

## Step 1: Configure kubectls for two clusters

```bash
# Merge kubeconfigs
KUBECONFIG=~/.kube/cluster-a:~/.kube/cluster-b \
  kubectl config view --flatten > ~/.kube/config

kubectl config get-contexts
# CURRENT   NAME        CLUSTER
# *         cluster-a   cluster-a
#           cluster-b   cluster-b
```

## Step 2: Run experiments on both clusters simultaneously

```bash
# Apply chaos to cluster-a
kubectl --context=cluster-a apply -f pod-delete-engine.yaml

# Apply chaos to cluster-b
kubectl --context=cluster-b apply -f pod-delete-engine.yaml

# Watch results from both
kubectl --context=cluster-a get chaosresult -n litmus -w &
kubectl --context=cluster-b get chaosresult -n litmus -w &
```

## Step 3: Argo Workflow — multi-cluster DAG

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: multi-cluster-chaos
spec:
  templates:
    - name: pipeline
      dag:
        tasks:
          - name: chaos-region-a
            template: apply-chaos
            arguments:
              parameters:
                - name: context
                  value: cluster-a

          - name: chaos-region-b
            template: apply-chaos
            dependencies: []   # run in parallel with region-a
            arguments:
              parameters:
                - name: context
                  value: cluster-b

    - name: apply-chaos
      inputs:
        parameters: [{name: context}]
      container:
        image: bitnami/kubectl:latest
        command: [kubectl, --context, "{{inputs.parameters.context}}", apply, -f, /manifests/pod-delete.yaml]
```

## Step 4: DNS failover validation

```bash
# Verify that GLB routes traffic to cluster-b when cluster-a is degraded
while true; do
  IP=$(dig +short my-app.example.com)
  echo "$(date +%T) → $IP"
  sleep 2
done
# During chaos: IP should shift from 10.1.x.x to 10.2.x.x (cluster-b)
```

## Key SRE metrics for multi-cluster chaos

- **MTTR across clusters**: Did cluster-b absorb traffic within the RTO?
- **Replication lag**: Did postgres standby converge before primary was isolated?
- **DNS propagation time**: Was TTL short enough for fast failover?

---
*Part of the 100-Lesson Chaos Engineering Series.*
