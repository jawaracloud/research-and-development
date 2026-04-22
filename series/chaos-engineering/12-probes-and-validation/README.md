# 12 — Probes and Validation

> **Type:** How-To  
> **Phase:** Foundations

## Overview

LitmusChaos **probes** are the mechanism for validating the steady-state hypothesis. They run before, during, and after chaos injection and determine whether the experiment's verdict is `Pass` or `Fail`.

## Probe Types

### 1. httpProbe

Calls an HTTP endpoint and evaluates the response code.

```yaml
probe:
  - name: "api-health"
    type: httpProbe
    mode: Continuous
    runProperties:
      probeTimeout: "5s"
      retry: 2
      interval: "5s"
    httpProbe/inputs:
      url: "http://target-app:8080/health"
      method:
        get:
          criteria: "=="
          responseCode: "200"
```

### 2. cmdProbe

Runs a shell command and checks its exit code or output.

```yaml
probe:
  - name: "replica-check"
    type: cmdProbe
    mode: Edge
    runProperties:
      probeTimeout: "10s"
      retry: 1
      interval: "5s"
    cmdProbe/inputs:
      command: >
        kubectl get deployment target-app -o jsonpath='{.status.readyReplicas}'
      comparator:
        type: int
        criteria: ">="
        value: "2"
      source: inline
```

### 3. promProbe

Queries Prometheus and validates the result against a threshold.

```yaml
probe:
  - name: "error-rate"
    type: promProbe
    mode: OnChaos
    runProperties:
      probeTimeout: "10s"
      retry: 1
      interval: "5s"
    promProbe/inputs:
      endpoint: "http://prometheus:9090"
      query: |
        sum(rate(http_requests_total{status=~"5.."}[1m]))
        / sum(rate(http_requests_total[1m]))
      comparator:
        criteria: "<"
        value: "0.01"
```

### 4. k8sProbe

Checks Kubernetes resource state.

```yaml
probe:
  - name: "deployment-available"
    type: k8sProbe
    mode: EOT
    runProperties:
      probeTimeout: "30s"
      retry: 3
      interval: "5s"
    k8sProbe/inputs:
      group: apps
      version: v1
      resource: deployments
      namespace: default
      fieldSelector: "metadata.name=target-app"
      operation: present
```

## Probe Modes Cheatsheet

| Mode | When |
|------|------|
| `SOT` | Before chaos starts |
| `EOT` | After chaos ends |
| `Edge` | Before AND after |
| `Continuous` | Throughout entire experiment |
| `OnChaos` | Only during active injection |

## Multiple probes

You can combine multiple probes in one engine:

```yaml
probe:
  - name: http-check
    type: httpProbe
    mode: Continuous
    # ...
  - name: prom-check
    type: promProbe
    mode: OnChaos
    # ...
  - name: post-chaos-replicas
    type: k8sProbe
    mode: EOT
    # ...
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
