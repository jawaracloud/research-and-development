# 18 — ChaosHub

> **Type:** Reference  
> **Phase:** Foundations

## Overview

**ChaosHub** is LitmusChaos's library of pre-built, production-tested chaos experiments. Think of it as the "npm registry" for chaos experiments.

## What ChaosHub Provides

- 50+ curated `ChaosExperiment` definitions
- Organized by category (Generic, Kubernetes, AWS, GCP, Azure, VMware)
- Versioned alongside the LitmusChaos operator
- Installable via `kubectl apply` or ChaosCenter UI

## ChaosHub Categories

| Category | Experiments |
|----------|------------|
| **Generic / Pod** | pod-delete, pod-cpu-hog, pod-memory-hog, pod-network-* |
| **Generic / Node** | node-cpu-hog, node-memory-hog, node-drain, node-taint |
| **Generic / Container** | container-kill |
| **Kubernetes / Control Plane** | kube-apiserver-latency |
| **AWS** | ec2-stop, ebs-loss, rds-instance-stop, lambda-delete |
| **GCP** | gcp-vm-instance-stop, gcp-disk-loss |
| **Azure** | azure-instance-stop, azure-disk-loss |
| **VMware** | VMware vSphere VM power off |

## Installing from ChaosHub

```bash
# Install a single experiment
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/pod-delete \
  -n litmus

# Install all generic experiments
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic \
  -n litmus
```

## Listing Installed Experiments

```bash
kubectl get chaosexperiment -n litmus
```

## ChaosHub API

Query the hub API to see all available experiments:

```bash
curl -s "https://hub.litmuschaos.io/api/chaos/3.9.0?item=all" \
  | jq '.[].metadata.name' | sort
```

## Custom ChaosHub

You can connect your own Git repository as a private ChaosHub in ChaosCenter:

1. Go to **ChaosHubs → Add Hub**
2. Provide your Git repo URL + branch
3. Experiments are pulled from `charts/<category>/<experiment>/`

## Experiment YAML format in ChaosHub

Each experiment in a hub follows this structure:
```
charts/
  generic/
    pod-delete/
      experiment.yaml    # ChaosExperiment CR
      rbac.yaml          # ServiceAccount + Role
      engine.yaml        # Sample ChaosEngine
      README.md
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
