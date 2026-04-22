# 74 — GitOps Chaos

> **Type:** How-To  
> **Phase:** Observability & Automation

## Overview

Treat chaos experiment manifests as GitOps resources — stored in Git, automatically synced by ArgoCD, and governed through PR review. This is **chaos-as-code** at its most disciplined.

## GitOps Chaos Architecture

```
Git Repository
  └── chaos/
      ├── experiments/          (ChaosExperiment CRDs)
      ├── engines/              (ChaosEngine definitions)
      ├── schedules/            (ChaosSchedule CRs)
      └── kustomization.yaml
         ↓
      ArgoCD watches this directory
         ↓
      Auto-syncs to cluster
         ↓
      LitmusChaos runs experiments
```

## Step 1: Directory structure

```
chaos-series-gitops/
├── base/
│   ├── kustomization.yaml
│   ├── experiments/
│   │   └── pod-delete.yaml    (ChaosExperiment CR)
│   └── rbac/
│       └── chaos-rbac.yaml
└── overlays/
    ├── staging/
    │   ├── kustomization.yaml
    │   └── engines/
    │       └── pod-delete-engine.yaml   (ChaosEngine — staging settings)
    └── production/
        ├── kustomization.yaml
        └── engines/
            └── pod-delete-engine.yaml  (ChaosEngine — prod settings, smaller blast radius)
```

## Step 2: ArgoCD Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: chaos-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/jawaracloud/chaos-experiments
    targetRevision: main
    path: overlays/staging
  destination:
    server: https://kubernetes.default.svc
    namespace: litmus
  syncPolicy:
    automated:
      prune: false         # don't auto-delete ChaosEngines
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Step 3: PR-based chaos approval workflow

1. Engineer opens PR: "Add network-latency chaos to staging"
2. Reviewer checks: blast radius, probe thresholds, duration
3. PR merged → ArgoCD syncs → ChaosEngine applied → LitmusChaos runs
4. ChaosResult visible in ChaosCenter and Slack exporter

## Step 4: Kustomize overlay for prod (reduced blast radius)

```yaml
# overlays/production/engines/patch.yaml
- op: replace
  path: /spec/experiments/0/spec/components/env/0/value
  value: "10"    # PODS_AFFECTED_PERC reduced to 10% in production
```

## Benefits of GitOps chaos

| Benefit | How |
|---------|-----|
| Audit trail | Every experiment change has a commit + PR |
| Rollback | `git revert` → ArgoCD removes ChaosEngine |
| Review gate | PR approval required before injection |
| Environment promotion | Staging → production via kustomize overlay |

---
*Part of the 100-Lesson Chaos Engineering Series.*
