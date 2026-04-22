# 11 — Your First Pod Delete Experiment

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

Run a `pod-delete` experiment against the `target-app` deployment and verify the steady-state hypothesis holds.

**Hypothesis**: When 50% of `target-app` pods are deleted, the health endpoint continues to return HTTP 200 with < 500 ms latency.

## Prerequisites

- Cluster running (lesson 07)
- `target-app` deployed (lesson 08)
- LitmusChaos operator running

## Step 1: Install the pod-delete ChaosExperiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/pod-delete \
  -n litmus
```

## Step 2: Create the ChaosEngine

`pod-delete-engine.yaml`:

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: first-pod-delete
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  monitoring: true
  jobCleanUpPolicy: retain
  annotationCheck: "false"
  engineState: active
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: FORCE
              value: "false"
            - name: PODS_AFFECTED_PERC
              value: "50"
        probe:
          - name: "health-endpoint"
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "5s"
              retry: 2
              interval: "5s"
              probePollingInterval: "2s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/health"
              insecureSkipVerify: false
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## Step 3: Apply and watch

```bash
kubectl apply -f pod-delete-engine.yaml

# Watch pods being deleted
kubectl get pods -n default -w

# Watch experiment status
kubectl describe chaosengine first-pod-delete -n litmus
```

## Step 4: Check the result

```bash
kubectl get chaosresult -n litmus
kubectl describe chaosresult first-pod-delete-pod-delete -n litmus
```

## Expected output

```
Experiment Details:
  Phase:    Completed
  Verdict:  Pass
Probe Status:
  Name:    health-endpoint
  Status:
    Continuous: Passed
```

## Key takeaways

- The `target-app` Deployment has 3 replicas; deleting 50% leaves 1–2 pods active
- Kubernetes' built-in self-healing (ReplicaSet controller) restored pods within seconds
- The HTTP probe ran continuously and never saw a non-200 response

---
*Part of the 100-Lesson Chaos Engineering Series.*
