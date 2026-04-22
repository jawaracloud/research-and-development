# 75 — Chaos as Code

> **Type:** Explanation  
> **Phase:** Observability & Automation

## Overview

**Chaos-as-code** is the practice of expressing every chaos experiment — its target, parameters, probes, and schedule — as version-controlled code rather than ad-hoc CLI commands or GUI actions.

## Why Chaos-as-Code?

| Ad-hoc chaos | Chaos-as-code |
|-------------|---------------|
| Tribal knowledge | Shared, documented |
| Unrepeatable | Deterministic replay |
| No audit trail | Full commit history |
| Hard to review | PR review gate |
| Env-specific config in heads | Kustomize overlays |

## Core Artefacts

### 1. ChaosExperiment (what fault)
```yaml
# chaos/experiments/pod-delete.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: pod-delete
  namespace: litmus
  labels:
    version: "3.9.0"
    category: pod
```

### 2. ChaosEngine (target + parameters)
```yaml
# chaos/engines/frontend-pod-delete.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: frontend-pod-delete
  annotations:
    chaos.jawaracloud.com/owner: "platform-team"
    chaos.jawaracloud.com/ticket: "INFRA-1234"
    chaos.jawaracloud.com/hypothesis: "25% pod loss does not breach SLO"
spec:
  appinfo:
    appns: production
    applabel: "tier=frontend"
    appkind: deployment
```

### 3. ChaosSchedule (when)
```yaml
# chaos/schedules/weekly-frontend.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosSchedule
metadata:
  name: weekly-frontend-chaos
spec:
  schedule:
    repeat:
      workDays:
        includedDays: "Tue,Thu"
      workHours:
        includedHours: "2"
```

## Go-based Chaos Test (hypothesis validation)

```go
// chaos_test.go
package chaos_test

import (
    "testing"
    "time"
    "net/http"
)

// TestPodDeleteHypothesis validates that deleting 50% of pods
// does not cause > 1% error rate.
func TestPodDeleteHypothesis(t *testing.T) {
    // Pre-chaos baseline
    assertErrorRateBelowThreshold(t, 0.01, "pre-chaos")

    // Apply chaos
    applyChaosEngine(t, "chaos/engines/pod-delete.yaml")
    defer deleteChaosEngine(t, "first-pod-delete")

    // During chaos
    time.Sleep(30 * time.Second)
    assertErrorRateBelowThreshold(t, 0.01, "during-chaos")

    // Post chaos recovery
    time.Sleep(60 * time.Second)
    assertErrorRateBelowThreshold(t, 0.001, "post-chaos")
}
```

## Repository layout recommendation

```
chaos/
├── experiments/       # ChaosExperiment CRDs (what fault)
├── engines/           # ChaosEngine per service (who + params)
├── schedules/         # ChaosSchedule per cadence
├── workflows/         # Argo/Tekton multi-step workflows
├── hypothesis/        # Go test files with hypothesis assertions
├── runbooks/          # Markdown incident response guides
└── reports/           # Post-GameDay finding reports
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
