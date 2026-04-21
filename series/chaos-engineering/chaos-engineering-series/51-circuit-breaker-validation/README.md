# 51 — Circuit Breaker Validation

> **Type:** How-To  
> **Phase:** Application & Network Chaos

## Overview

This lesson validates that your circuit breaker implementation trips correctly under sustained upstream failures, preventing cascading overload and recovering gracefully when the upstream recovers.

## The Circuit Breaker Pattern

```
CLOSED → OPEN → HALF-OPEN → CLOSED
```

| State | Behavior |
|-------|---------|
| **Closed** | Requests flow normally; errors counted |
| **Open** | Requests fail-fast; no calls to upstream |
| **Half-Open** | Trial requests sent; if pass → Closed; if fail → Open |

## Step 1: Implement a circuit breaker in Go (using `sony/gobreaker`)

```go
package main

import (
    "errors"
    "fmt"
    "net/http"
    "time"

    "github.com/sony/gobreaker"
)

var cb *gobreaker.CircuitBreaker

func init() {
    settings := gobreaker.Settings{
        Name:        "postgres-cb",
        MaxRequests: 3,                    // half-open: allow 3 trial requests
        Interval:    10 * time.Second,     // reset count window
        Timeout:     30 * time.Second,     // open → half-open after 30s
        ReadyToTrip: func(counts gobreaker.Counts) bool {
            failureRatio := float64(counts.TotalFailures) /
                float64(counts.Requests)
            return counts.Requests >= 5 && failureRatio >= 0.6
        },
        OnStateChange: func(name string, from, to gobreaker.State) {
            fmt.Printf("CB [%s]: %s → %s\n", name, from, to)
        },
    }
    cb = gobreaker.NewCircuitBreaker(settings)
}

func queryDB() error {
    _, err := cb.Execute(func() (interface{}, error) {
        // simulated DB call
        resp, err := http.Get("http://localhost:5432/ping")
        if err != nil || resp.StatusCode >= 500 {
            return nil, errors.New("db error")
        }
        return resp, nil
    })
    return err
}
```

## Step 2: Inject failures with Toxiproxy and watch the CB trip

```bash
# Add timeout toxic (simulates unresponsive DB)
curl -XPOST http://localhost:8474/proxies/postgres/toxics \
  -d '{"name":"timeout","type":"timeout","attributes":{"timeout":100}}'

# Run the app; watch circuit breaker open
go run main.go
# CB [postgres-cb]: closed → open
# CB [postgres-cb]: open → half-open (after 30s)
# CB [postgres-cb]: half-open → closed (if DB recovered)
```

## Step 3: Remove toxic and verify CB closes

```bash
curl -XDELETE http://localhost:8474/proxies/postgres/toxics/timeout
# After 30s, CB moves to half-open, trial succeeds, CB closes
```

## Circuit Breaker Metrics

```go
// Expose CB state as Prometheus gauge
cbStateGauge := prometheus.NewGaugeVec(...)
cb.OnStateChange = func(name string, from, to gobreaker.State) {
    cbStateGauge.WithLabelValues(name).Set(float64(to))
}
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
