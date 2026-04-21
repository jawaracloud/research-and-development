# 16 — Chaos Results

> **Type:** Reference  
> **Phase:** Foundations

## Overview

`ChaosResult` is the output artifact of every `ChaosEngine` run. It records the experiment's verdict, probe statuses, history, and timing — everything needed to understand whether your system passed the resilience test.

## ChaosResult Structure

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosResult
metadata:
  name: <engine-name>-<experiment-name>
  namespace: litmus
spec:
  engine: first-pod-delete
  experiment: pod-delete
status:
  experimentStatus:
    phase: Completed      # Awaited | Running | Completed
    verdict: Pass         # Pass | Fail | Stopped | Awaited
    failStep: "N/A"       # Which step failed (if Fail)
    probeSuccessPercentage: "100"
  probeStatus:
    - name: health-endpoint
      type: HTTPProbe
      mode: Continuous
      status:
        continuous: Passed
  experimentDetails:
    chaosDuration: 30
    chaosInterval: 10
    revertChaos: true
  history:
    passedRuns: 5
    failedRuns: 0
    stoppedRuns: 1
```

## Verdict Values

| Verdict | Meaning |
|---------|---------|
| `Pass` | Hypothesis held; all probes passed |
| `Fail` | Hypothesis violated; one or more probes failed |
| `Stopped` | Experiment was manually stopped |
| `Awaited` | Experiment is still in progress |

## Phase Values

| Phase | Meaning |
|-------|---------|
| `Awaited` | Waiting for resources |
| `Running` | Chaos injection active |
| `Completed` | Experiment finished |

## Querying Results

```bash
# List all results
kubectl get chaosresult -n litmus

# Full details
kubectl describe chaosresult first-pod-delete-pod-delete -n litmus

# JSON output for scripting
kubectl get chaosresult first-pod-delete-pod-delete -n litmus -o json \
  | jq '.status.experimentStatus.verdict'
# "Pass"

# Check history
kubectl get chaosresult first-pod-delete-pod-delete -n litmus -o json \
  | jq '.status.history'
# { "passedRuns": 5, "failedRuns": 0 }
```

## Using Results in Automation

```bash
#!/usr/bin/env bash
VERDICT=$(kubectl get chaosresult my-engine-pod-delete -n litmus \
  -o jsonpath='{.status.experimentStatus.verdict}')

if [ "$VERDICT" != "Pass" ]; then
  echo "❌ Chaos experiment FAILED: $VERDICT"
  exit 1
fi
echo "✅ Chaos experiment PASSED"
```

## Retention Policy

Controlled by `jobCleanUpPolicy` in the ChaosEngine:

| Policy | Effect |
|--------|--------|
| `retain` | ChaosResult kept after experiment |
| `delete` | ChaosResult deleted after experiment |

Use `retain` during development; `delete` for scheduled continuous chaos.

---
*Part of the 100-Lesson Chaos Engineering Series.*
