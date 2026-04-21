# 15 — Chaos Schedules

> **Type:** How-To  
> **Phase:** Foundations

## Overview

`ChaosSchedule` is a LitmusChaos CRD that runs a `ChaosEngine` on a repeating cron-based schedule — enabling continuous, automated chaos without manual intervention.

## ChaosSchedule CR

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosSchedule
metadata:
  name: scheduled-pod-delete
  namespace: litmus
spec:
  schedule:
    now: false
    once:
      executionTime: ""           # leave blank for cron
    repeat:
      timeRange:
        startTime: "2026-01-01T02:00:00Z"
        endTime:   "2026-12-31T04:00:00Z"
      properties:
        minChaosInterval: "2m"   # minimum time between runs
      workDays:
        includedDays: "Mon,Tue,Wed,Thu,Fri"
      workHours:
        includedHours: "2,3"     # 02:00–04:00 UTC
  engineTemplateSpec:
    appinfo:
      appns: default
      applabel: "app=target-app"
      appkind: deployment
    chaosServiceAccount: litmus-admin
    jobCleanUpPolicy: delete
    experiments:
      - name: pod-delete
        spec:
          components:
            env:
              - name: TOTAL_CHAOS_DURATION
                value: "30"
              - name: PODS_AFFECTED_PERC
                value: "25"
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

## Apply and Verify

```bash
kubectl apply -f chaos-schedule.yaml

# Check schedule status
kubectl get chaosschedule -n litmus
kubectl describe chaosschedule scheduled-pod-delete -n litmus
```

## Halt / Resume a Schedule

```bash
# Halt (pause) the schedule
kubectl patch chaosschedule scheduled-pod-delete -n litmus \
  --type=merge -p '{"spec":{"scheduleState":"halt"}}'

# Resume
kubectl patch chaosschedule scheduled-pod-delete -n litmus \
  --type=merge -p '{"spec":{"scheduleState":"active"}}'
```

## Watching Generated Engines

Each schedule run creates a new `ChaosEngine`:

```bash
kubectl get chaosengine -n litmus -w
```

## Best Practices

- Schedule chaos during **off-peak** hours when blast radius impact is minimal
- Start with `minChaosInterval: "1h"` and reduce as confidence grows
- Always include probes so the schedule self-validates
- Use `workDays` to skip weekends unless you're testing weekend resilience

---
*Part of the 100-Lesson Chaos Engineering Series.*
