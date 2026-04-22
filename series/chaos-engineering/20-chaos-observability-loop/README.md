# 20 — The Chaos Observability Loop

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

The **chaos observability loop** is the closed-loop feedback cycle that makes chaos engineering scientific rather than random. It connects experiment execution directly to measurement systems, enabling automated hypothesis validation.

## The Loop

```
┌──────────────────────────────────────────────────────────────────────┐
│                    CHAOS OBSERVABILITY LOOP                          │
│                                                                      │
│   1. DEFINE          2. BASELINE         3. INJECT                  │
│   Hypothesis    →    Measure normal  →   Apply ChaosEngine          │
│   (SLO-based)        metric state        (fault injection)           │
│                                               ↓                      │
│   6. IMPROVE         5. FIX               4. OBSERVE                │
│   Architecture  ←    Weakness       ←    Prometheus/Grafana          │
│   & runbooks         found               probes + k6 load            │
└──────────────────────────────────────────────────────────────────────┘
```

## Step-by-Step

### 1. Define Hypothesis
Formalize the steady-state (lesson 03). Anchor to your SLO.

### 2. Establish Baseline
Collect 24–48 hours of production metrics at normal traffic levels. This is your "healthy" benchmark.

```promql
# Record baseline p99 latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

### 3. Inject Fault
Apply the chaos experiment (ChaosEngine, Chaos Mesh CR, k6 fault injection).

### 4. Observe in Real Time

Tools at each layer:

| Layer | Tool |
|-------|------|
| Infrastructure | kube-state-metrics, node-exporter |
| Application | Prometheus (custom metrics), OpenTelemetry |
| Network | Toxiproxy metrics, CNI-level stats |
| Business | Transaction success rate, conversion rate |

### 5. Validate & Analyse
- Did probes pass? → ChaosResult verdict
- Did SLO burn rate stay within bounds?
- Were there cascading failures?

### 6. Fix and Improve
Every `Fail` verdict is a gift: it points to a specific weakness. Fix it, re-run, compare.

## Tight Feedback: Under 10 Minutes

For CI integration, the entire loop should complete in < 10 minutes:

```
Baseline scrape:    30 s
Chaos injection:    60–120 s
Probe evaluation: continuous
Result collection:  30 s
CI gate:            pass/fail
Total:              ~5 min
```

## Key Prometheus Recording Rules

```yaml
groups:
  - name: chaos_baseline
    rules:
      - record: baseline:p99_latency:5m
        expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
      - record: baseline:error_rate:1m
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[1m]))
          / sum(rate(http_requests_total[1m]))
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
