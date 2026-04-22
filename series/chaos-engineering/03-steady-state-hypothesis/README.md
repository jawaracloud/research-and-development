# 03 — Steady-State Hypothesis

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

The **steady-state hypothesis** is the heartbeat of any chaos experiment. Without it, you are just breaking things randomly. With it, you run a scientific experiment that either increases or decreases your confidence in system resilience.

## Definition

The steady-state hypothesis describes the **measurable, observable signals** that indicate the system is operating normally. It takes the form:

> _"While chaos is injected, metric X will remain within threshold Y."_

## Components of a Hypothesis

```
┌─────────────────────────────────────────────────────────────┐
│  HYPOTHESIS                                                  │
│                                                              │
│  When: [failure condition]                                   │
│  The system: [subject]                                       │
│  Will: [expected behaviour]                                  │
│  As measured by: [concrete metric + threshold]               │
└─────────────────────────────────────────────────────────────┘
```

### Example

> **When** 50% of frontend pods are deleted,  
> **The system** will continue to serve requests  
> **With** p99 latency < 500 ms and error rate < 1%  
> **As measured by** Prometheus `http_request_duration_seconds` and `http_requests_total{status=~"5.."}`

## Probes in LitmusChaos

LitmusChaos validates the steady-state hypothesis using **probes**:

| Probe Type | What it checks |
|------------|---------------|
| `httpProbe` | HTTP endpoint returns expected status code |
| `cmdProbe` | Shell command exits 0 |
| `promProbe` | Prometheus query result within threshold |
| `k8sProbe` | Kubernetes resource is in expected state |

### Probe Modes

| Mode | When it runs |
|------|-------------|
| `SOT` | Start of test (pre-chaos) |
| `EOT` | End of test (post-chaos) |
| `Edge` | Both SOT and EOT |
| `Continuous` | Throughout the entire experiment |
| `OnChaos` | Only during the chaos injection window |

## Good vs. Bad Hypotheses

| ❌ Too vague | ✅ Measurable |
|-------------|--------------|
| "App stays up" | "Health endpoint returns 200 within 200 ms" |
| "No errors" | "Error rate < 0.1% over 1-minute window" |
| "Database works" | "Read latency p99 < 50 ms; write success rate > 99.9%" |

## Workflow

```
1. Measure baseline (collect steady-state metrics before experiment)
2. Define hypothesis thresholds (derive from SLOs or SLAs)
3. Inject chaos
4. Continuously measure against thresholds
5. Verdict: PASS (hypothesis held) or FAIL (system deviated)
6. Revert and analyse
```

## Connection to SLOs

Steady-state thresholds **should directly reflect your SLOs**. If your SLO says "99.9% of requests complete in < 1s", your chaos hypothesis should use the same threshold.

---
*Part of the 100-Lesson Chaos Engineering Series.*
