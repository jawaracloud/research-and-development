# 55 — Fallback Validation

> **Type:** How-To  
> **Phase:** Application & Network Chaos

## Overview

This lesson validates that fallback mechanisms (cached responses, static defaults, degraded-mode logic) activate correctly when a primary dependency is unavailable — and that the fallback is distinguishable from a real response.

## Fallback Hierarchy

```
Request
   ↓
Primary source (Database)
   ↓ [fails]
Secondary source (Redis cache)
   ↓ [fails]
In-memory fallback (stale cache)
   ↓ [fails]
Static default response
```

## Step 1: Implement layered fallback in Go

```go
package main

import (
    "context"
    "encoding/json"
    "errors"
    "fmt"
    "log"
    "net/http"
    "sync"
    "time"
)

type UserService struct {
    db          DBAdapter
    cache       CacheAdapter
    localCache  sync.Map
    staticFallback []byte
}

func (s *UserService) GetUser(ctx context.Context, id int) ([]byte, string, error) {
    // 1. Try database
    user, err := s.db.FindByID(ctx, id)
    if err == nil {
        data, _ := json.Marshal(user)
        s.localCache.Store(id, data)  // warm local cache
        return data, "db", nil
    }
    log.Printf("DB unavailable: %v; trying cache", err)

    // 2. Try Redis cache
    cached, err := s.cache.Get(ctx, fmt.Sprintf("user:%d", id))
    if err == nil {
        return []byte(cached), "cache", nil
    }
    log.Printf("Cache unavailable: %v; trying local", err)

    // 3. In-memory local cache (stale)
    if local, ok := s.localCache.Load(id); ok {
        return local.([]byte), "stale", nil
    }

    // 4. Static fallback
    return s.staticFallback, "static", errors.New("all sources unavailable")
}

func handler(svc *UserService) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
        defer cancel()

        data, source, err := svc.GetUser(ctx, 1)
        w.Header().Set("X-Data-Source", source)  // visible to caller!
        if err != nil {
            w.Header().Set("X-Degraded", "true")
        }
        w.WriteHeader(http.StatusOK)
        w.Write(data)
    }
}
```

## Step 2: Test with Toxiproxy disabling DB

```bash
# Disable DB proxy
curl -XPOST http://localhost:8474/proxies/postgres/toxics \
  -d '{"name":"reset","type":"reset_peer","attributes":{"timeout":0}}'

# Call the endpoint and check headers
curl -v http://localhost:8080/user/1
# X-Data-Source: cache   ← served from Redis cache
# X-Degraded: (absent)

# Disable cache too (direct Redis kill)
docker compose stop redis

curl -v http://localhost:8080/user/1
# X-Data-Source: stale   ← served from in-memory
# X-Degraded: true
```

## Step 3: Prometheus metrics for fallback activation

```go
dataSourceCounter := prometheus.NewCounterVec(
    prometheus.CounterOpts{Name: "user_service_requests_total"},
    []string{"source"},
)
// Increment with source label on each request
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
