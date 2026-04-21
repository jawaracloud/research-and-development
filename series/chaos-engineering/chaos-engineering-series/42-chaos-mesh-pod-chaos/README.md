# 42 — Chaos Mesh PodChaos

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Use Chaos Mesh's `PodChaos` CR to kill pods and inject container failures — the Chaos Mesh equivalent of LitmusChaos pod-delete.

## PodChaos Actions

| Action | Effect |
|--------|--------|
| `pod-kill` | Deletes the pod (Deployment restarts it) |
| `pod-failure` | Marks pod as failed for `duration`; then restores |
| `container-kill` | Kills a specific container within the pod |

## Step 1: pod-kill

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-kill-example
  namespace: default
spec:
  action: pod-kill
  mode: FixedPercent
  value: "50"
  selector:
    namespaces: [default]
    labelSelectors:
      app: target-app
  duration: "30s"
```

## Step 2: pod-failure

Pod failure keeps the pod alive but marks it unhealthy. All containers in the pod enter an error state:

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure-example
  namespace: default
spec:
  action: pod-failure
  mode: One
  selector:
    namespaces: [default]
    labelSelectors:
      app: target-app
  duration: "60s"
```

## Step 3: container-kill (specific container)

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: container-kill-example
  namespace: default
spec:
  action: container-kill
  mode: All
  selector:
    namespaces: [default]
    labelSelectors:
      app: target-app
  containerNames: [target-app]
  duration: "30s"
```

## Apply and observe

```bash
kubectl apply -f pod-chaos.yaml

# Watch pod status
kubectl get pods -n default -w

# Get experiment status
kubectl get podchaos -n default
kubectl describe podchaos pod-kill-example -n default

# Clean up
kubectl delete podchaos pod-kill-example -n default
```

## Chaos Mesh Mode Options

| Mode | Description |
|------|-------------|
| `One` | Select 1 random pod |
| `All` | All matching pods |
| `Fixed` | Exactly N pods (set `value`) |
| `FixedPercent` | N% of pods (set `value` as %) |
| `RandomMaxPercent` | Up to N% (set `value` as %) |

---
*Part of the 100-Lesson Chaos Engineering Series.*
