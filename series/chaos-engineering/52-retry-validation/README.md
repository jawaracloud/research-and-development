# 52 — Retry Validation

> **Type:** How-To  
> **Phase:** Application & Network Chaos

## Overview

This lesson validates that retry logic in your Go application handles transient upstream failures correctly under chaos — retrying with exponential backoff, respecting context deadlines, and not amplifying load during outages (retry storm prevention).

## The Retry Storm Problem

Naive retries under chaos make things worse:

```
┌──────────────────────────────────────────────────────────────┐
│  100 clients × 3 retries = 300 requests during 30s outage   │
│  Each retry doubles the write amplification on the upstream  │
│  → Retry storm prevents the upstream from recovering         │
└──────────────────────────────────────────────────────────────┘
```

## Step 1: Exponential backoff with jitter

```go
package main

import (
    "context"
    "fmt"
    "math"
    "math/rand"
    "net/http"
    "time"
)

func retryWithBackoff(ctx context.Context, maxAttempts int, fn func() error) error {
    for attempt := 0; attempt < maxAttempts; attempt++ {
        err := fn()
        if err == nil {
            return nil
        }

        if attempt == maxAttempts-1 {
            return fmt.Errorf("all %d attempts failed: %w", maxAttempts, err)
        }

        // Exponential backoff with jitter
        base := time.Duration(math.Pow(2, float64(attempt))) * 100 * time.Millisecond
        jitter := time.Duration(rand.Int63n(int64(base / 2)))
        wait := base + jitter

        select {
        case <-ctx.Done():
            return ctx.Err()
        case <-time.After(wait):
        }
    }
    return nil
}

func callUpstream(ctx context.Context) error {
    return retryWithBackoff(ctx, 5, func() error {
        req, _ := http.NewRequestWithContext(ctx, "GET", "http://localhost:8080/health", nil)
        resp, err := http.DefaultClient.Do(req)
        if err != nil {
            return err
        }
        if resp.StatusCode >= 500 {
            return fmt.Errorf("upstream 5xx: %d", resp.StatusCode)
        }
        return nil
    })
}
```

## Step 2: Test under Toxiproxy timeout

```bash
# Add timeout toxic
curl -XPOST http://localhost:8474/proxies/postgres/toxics \
  -d '{"name":"timeout","type":"timeout","attributes":{"timeout":200}}'

# Run with context deadline
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()
err := callUpstream(ctx)
```

## Step 3: Retry-After header respect

```go
if resp.StatusCode == 429 || resp.StatusCode == 503 {
    if retryAfter := resp.Header.Get("Retry-After"); retryAfter != "" {
        d, _ := time.ParseDuration(retryAfter + "s")
        time.Sleep(d)
    }
}
```

## Idempotency guard

Only retry idempotent operations (GET, HEAD, PUT). Never retry non-idempotent writes (POST, PATCH) without server-side idempotency keys.

---
*Part of the 100-Lesson Chaos Engineering Series.*
