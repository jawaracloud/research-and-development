# 54 — Bulkhead Pattern

> **Type:** How-To  
> **Phase:** Application & Network Chaos

## Overview

The **bulkhead pattern** isolates failures to a partition of resources, preventing one failing subsystem from exhausting resources for the entire application. Chaos engineering validates that bulkheads hold under load.

## The Origin (Naval Bulkhead)

A ship's hull is divided into watertight compartments (bulkheads). When one compartment floods, the others remain intact and the ship stays afloat.

In software: isolate thread pools, connection pools, and semaphores per dependency.

## Bulkhead Types

| Type | Implementation |
|------|---------------|
| Thread pool isolation | Separate goroutine pools per downstream |
| Connection pool isolation | Separate `*sql.DB` per service role |
| Semaphore isolation | `chan struct{}` limiting concurrency |
| Process isolation | Separate pods/containers |

## Step 1: Semaphore bulkhead in Go

```go
type Bulkhead struct {
    sem chan struct{}
}

func NewBulkhead(maxConcurrent int) *Bulkhead {
    return &Bulkhead{sem: make(chan struct{}, maxConcurrent)}
}

func (b *Bulkhead) Execute(ctx context.Context, fn func() error) error {
    select {
    case b.sem <- struct{}{}:
        defer func() { <-b.sem }()
        return fn()
    case <-ctx.Done():
        return fmt.Errorf("bulkhead full: %w", ctx.Err())
    }
}

// Usage:
dbBulkhead := NewBulkhead(10)   // max 10 concurrent DB calls
cacheBulkhead := NewBulkhead(50) // max 50 concurrent cache calls
```

## Step 2: Inject IO stress to saturate the DB bulkhead

```bash
# Add 500ms latency toxic to saturate the 10-slot DB bulkhead
curl -XPOST http://localhost:8474/proxies/postgres/toxics \
  -d '{"name":"latency","type":"latency","attributes":{"latency":500}}'
```

## Step 3: Observe bulkhead behavior with k6

```js
export const options = { vus: 100, duration: '30s' };
export default () => {
  const res = http.get('http://localhost:8080/echo');
  check(res, {
    'ok or bulkhead-rejected': (r) => r.status === 200 || r.status === 429
  });
}
```

Expected: 10 concurrent requests are served; 90 get 429 Too Many Requests — **not** 100 connections hanging (which would DoS the DB).

## Prometheus bulkhead metrics

```go
bulkheadRejections := prometheus.NewCounter(prometheus.CounterOpts{
    Name: "bulkhead_rejections_total",
})
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
