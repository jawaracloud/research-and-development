# 80 — Chaos Metrics API

> **Type:** Reference  
> **Phase:** Observability & Automation

## Overview

The LitmusChaos Prometheus exporter and Kubernetes Metrics API provide a programmatic interface for querying chaos experiment outcomes — enabling dashboards, CI gates, and automated reporting.

## LitmusChaos Prometheus Metrics Reference

| Metric Name | Type | Labels | Description |
|-------------|------|--------|-------------|
| `litmuschaos_passed_experiments` | Counter | `chaosengine_context`, `chaosexperiment`, `chaosnamespace`, `workflowName` | Total passed experiments |
| `litmuschaos_failed_experiments` | Counter | same | Total failed experiments |
| `litmuschaos_awaited_experiments` | Gauge | same | Currently running |
| `litmuschaos_experiment_verdict` | Gauge | same | 1=pass, 0=fail |
| `litmuschaos_experiment_start_epoch` | Gauge | same | Start time (Unix) |
| `litmuschaos_running_chaos_jobs` | Gauge | — | Active chaos jobs |

## Prometheus HTTP API

Query metrics programmatically:

```bash
# Get all currently running experiments
curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=litmuschaos_awaited_experiments > 0' \
  | jq '.data.result[] | {experiment: .metric.chaosexperiment, engine: .metric.chaosengine_context}'

# Pass rate across all experiments (last 7 days)
curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=increase(litmuschaos_passed_experiments[7d]) / (increase(litmuschaos_passed_experiments[7d]) + increase(litmuschaos_failed_experiments[7d]))' \
  | jq '.data.result[].value[1]'
```

## Go: querying Prometheus API

```go
package main

import (
    "context"
    "fmt"
    "time"

    "github.com/prometheus/client_golang/api"
    v1 "github.com/prometheus/client_golang/api/prometheus/v1"
    "github.com/prometheus/common/model"
)

func getChaosPassRate(endpoint string) (float64, error) {
    client, _ := api.NewClient(api.Config{Address: endpoint})
    pAPI := v1.NewAPI(client)
    result, _, err := pAPI.Query(context.Background(),
        `increase(litmuschaos_passed_experiments[24h]) / 
         (increase(litmuschaos_passed_experiments[24h]) + 
          increase(litmuschaos_failed_experiments[24h]))`,
        time.Now(),
    )
    if err != nil {
        return 0, err
    }
    vec := result.(model.Vector)
    if len(vec) == 0 {
        return 1.0, nil // no experiments = 100% pass rate
    }
    return float64(vec[0].Value), nil
}
```

## Kubernetes API: list ChaosResults

```go
gvr := schema.GroupVersionResource{
    Group:    "litmuschaos.io",
    Version:  "v1alpha1",
    Resource: "chaosresults",
}
list, _ := dynClient.Resource(gvr).Namespace("litmus").
    List(context.Background(), metav1.ListOptions{})

for _, item := range list.Items {
    verdict, _, _ := unstructured.NestedString(
        item.Object, "status", "experimentStatus", "verdict")
    fmt.Printf("%s: %s\n", item.GetName(), verdict)
}
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
