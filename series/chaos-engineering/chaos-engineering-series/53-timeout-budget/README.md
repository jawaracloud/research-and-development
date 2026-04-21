# 53 — Timeout Budget

> **Type:** How-To  
> **Phase:** Application & Network Chaos

## Overview

Every distributed system call should operate within a **timeout budget** — a hierarchy of deadlines that flows from the user's tolerance through every service hop. This lesson teaches you to measure and validate timeout budgets under chaos.

## The Timeout Budget Model

```
User tolerance: 3 s total
      │
   [API Gateway]  timeout: 2.5 s
         │
      [Service A] timeout: 2.0 s
            │
         [Service B] timeout: 1.5 s
               │
            [Database] timeout: 500 ms
```

If the DB takes 600 ms, Service B times out → error propagates up → user sees timeout.

## Step 1: Propagate context deadlines in Go

```go
// HTTP handler — extract the request context (has deadline from client)
func handler(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()   // inherits client's deadline

    // Call downstream with a shorter deadline
    ctx, cancel := context.WithTimeout(ctx, 1500*time.Millisecond)
    defer cancel()

    result, err := callServiceB(ctx)
    if errors.Is(err, context.DeadlineExceeded) {
        http.Error(w, `{"error":"upstream timeout"}`, http.StatusGatewayTimeout)
        return
    }
    // ...
}
```

## Step 2: Inject latency at each hop with Toxiproxy

```bash
# Add 600ms latency to "service-b" proxy (should exceed 500ms budget)
curl -XPOST http://localhost:8474/proxies/service-b/toxics \
  -d '{"name":"latency","type":"latency","attributes":{"latency":600}}'
```

Now observe:
- Service A detects DeadlineExceeded
- Returns 504 Gateway Timeout
- Client receives response in ~1500ms (not 600ms)

## Step 3: Measure timeout budget consumption

```go
func callServiceB(ctx context.Context) (string, error) {
    start := time.Now()
    defer func() {
        remaining, _ := ctx.Deadline()
        left := time.Until(remaining)
        log.Printf("callServiceB took %v; budget remaining: %v",
            time.Since(start), left)
    }()
    // ... actual call
}
```

## Timeout budget anti-patterns

| Anti-pattern | Risk |
|-------------|------|
| No timeout set | Goroutine blocked indefinitely |
| Fixed `30s` timeout everywhere | User waits 30s before seeing error |
| Same timeout at every layer | No budget left for downstream hops |
| Retry on timeout without reduced budget | Budget exhausted; still retrying |

## Verification query

```promql
# % of requests that timed out at DB layer
sum(rate(db_query_timeout_total[1m]))
/ sum(rate(db_query_total[1m]))
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
