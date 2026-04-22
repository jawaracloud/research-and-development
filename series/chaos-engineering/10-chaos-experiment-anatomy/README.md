# 10 — Anatomy of a Chaos Experiment

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

LitmusChaos uses Kubernetes Custom Resources to define and execute experiments. Understanding the structure of these CRs is essential before running your first experiment.

## Key Custom Resources

| CR | Purpose |
|----|---------|
| `ChaosExperiment` | Template for a single type of fault (e.g., pod-delete) |
| `ChaosEngine` | Binds an experiment to a target app + runs it |
| `ChaosResult` | Stores the verdict after the experiment completes |
| `ChaosSchedule` | Schedules ChaosEngines on a cron schedule |

## ChaosExperiment

Defines **what** to do (the experiment logic). Pulled from ChaosHub.

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: pod-delete
  namespace: litmus
spec:
  definition:
    scope: Namespaced
    permissions: [...]
    image: "litmuschaos/go-runner:3.9.0"
    imagePullPolicy: Always
    args: ["-c", "$(EXPERIMENT_NAME)"]
    command: ["/bin/bash"]
    env:
      - name: TOTAL_CHAOS_DURATION
        value: "30"
      - name: CHAOS_INTERVAL
        value: "10"
```

## ChaosEngine

Defines **who** (the target) and **when** (this run). One engine per experiment run.

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: my-pod-delete
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  monitoring: true
  jobCleanUpPolicy: retain         # or 'delete'
  annotationCheck: "false"
  engineState: active
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: PODS_AFFECTED_PERC
              value: "50"
        probe:
          - name: health-check
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "5s"
              retry: 2
              interval: "5s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/health"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## ChaosResult

Auto-created after an experiment run:

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosResult
metadata:
  name: my-pod-delete-pod-delete
  namespace: litmus
status:
  experimentStatus:
    phase: Completed
    verdict: Pass          # or Fail
  probeStatus:
    - name: health-check
      type: HTTPProbe
      status:
        continuous: Passed
  history:
    passedRuns: 3
    failedRuns: 0
```

## Lifecycle of a ChaosEngine

```
engineState: active
      ↓
Pre-chaos validation (SOT probes)
      ↓
Chaos injection (fault job runs)
      ↓
Continuous probe monitoring
      ↓
Post-chaos validation (EOT probes)
      ↓
ChaosResult written (Pass / Fail)
      ↓
engineState: stopped
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
