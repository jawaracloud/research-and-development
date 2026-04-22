# 06 — Chaos Tooling Landscape

> **Type:** Reference  
> **Phase:** Foundations

## Overview

The chaos engineering ecosystem has grown enormously. This lesson surveys the major tools, their strengths, and when to use each.

## Tool Comparison

| Tool | Maintained By | Model | Best For |
|------|--------------|-------|----------|
| **LitmusChaos** | CNCF (Incubating) | Kubernetes CRDs | K8s-native, open-source |
| **Chaos Mesh** | CNCF (Incubating) | Kubernetes CRDs | Fine-grained K8s + time chaos |
| **Gremlin** | Gremlin Inc. | SaaS | Enterprise, multi-cloud |
| **AWS FIS** | AWS | Managed service | AWS-native infra chaos |
| **Azure Chaos Studio** | Microsoft | Managed service | Azure-native |
| **Toxiproxy** | Shopify | Proxy sidecar | Network fault simulation |
| **Chaos Toolkit** | ChaosIQ | Python CLI | Policy-driven, multi-layer |
| **Pumba** | Alexei Ledenev | Docker daemon | Container-level |

## LitmusChaos

- **Architecture**: Operator + ChaosHub (pre-built experiment library) + ChaosCenter (GUI)
- **Experiments**: 50+ curated (pod, node, network, I/O, application)
- **Strengths**: Rich probe system, Argo-based workflows, resilience scoring
- **This series uses**: LitmusChaos as the primary tool

```bash
kubectl apply -f https://litmuschaos.github.io/litmus/litmus-operator-v3.9.0.yaml
```

## Chaos Mesh

- **Architecture**: Operator + dashboard + chaos-daemon (per-node DaemonSet)
- **Unique features**: `TimeChaos`, `JVMChaos`, `HTTPChaos`, `KernelChaos`
- **Strengths**: Fine-grained control, excellent dashboard, Grafana integration

```bash
helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh
```

## Toxiproxy

- **Architecture**: TCP proxy with a REST API to inject toxics (latency, timeout, bandwidth, etc.)
- **Use case**: Simulate application-layer network faults without K8s
- **Strengths**: Lightweight, language-agnostic, perfect for service dependency testing

## Gremlin

- **Architecture**: SaaS control plane + agent installed on hosts/containers
- **Strengths**: Enterprise audit trail, team management, automatic rollback
- **Cost**: Commercial

## AWS Fault Injection Service (FIS)

- **Architecture**: AWS-managed; targets EC2, ECS, EKS, RDS, etc.
- **Strengths**: Deep AWS integration, IAM-controlled blast radius
- **Use case**: Cloud-layer chaos (AZ outage, RDS failover, EC2 termination)

## Decision Guide

```
Need K8s-native open-source?     → LitmusChaos or Chaos Mesh
Need app-layer network faults?   → Toxiproxy
Need AWS infra chaos?            → AWS FIS
Need enterprise SaaS?            → Gremlin
Need time manipulation?          → Chaos Mesh (TimeChaos)
Need JVM chaos?                  → Chaos Mesh (JVMChaos)
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
