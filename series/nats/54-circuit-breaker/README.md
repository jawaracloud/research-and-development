# 54 — Circuit Breaker with NATS

> **Type:** How-To  
> **Phase:** Patterns & Architecture

## Overview

Implement a circuit breaker around NATS request/reply calls to prevent cascading failures when a downstream service is unavailable.

## Circuit Breaker States

```
CLOSED → failures < threshold → all requests pass through
   ↓
Failures exceed threshold (N in window)
   ↓
OPEN → all requests fail fast (no network call)
   ↓
After reset timeout
   ↓
HALF-OPEN → 1 test request
   ↓
If success → CLOSED; if failure → OPEN
```

## Go Implementation

```go
package circuitbreaker

import (
    "errors"
    "sync"
    "time"
)

var ErrOpen = errors.New("circuit breaker is open")

type State int

const (
    Closed   State = iota
    Open
    HalfOpen
)

type CircuitBreaker struct {
    mu           sync.Mutex
    state        State
    failures     int
    threshold    int
    resetTimeout time.Duration
    lastFailure  time.Time
}

func New(threshold int, resetTimeout time.Duration) *CircuitBreaker {
    return &CircuitBreaker{threshold: threshold, resetTimeout: resetTimeout}
}

func (cb *CircuitBreaker) Execute(fn func() ([]byte, error)) ([]byte, error) {
    cb.mu.Lock()
    switch cb.state {
    case Open:
        if time.Since(cb.lastFailure) > cb.resetTimeout {
            cb.state = HalfOpen
        } else {
            cb.mu.Unlock()
            return nil, ErrOpen
        }
    }
    cb.mu.Unlock()

    result, err := fn()

    cb.mu.Lock()
    defer cb.mu.Unlock()
    if err != nil {
        cb.failures++
        cb.lastFailure = time.Now()
        if cb.state == HalfOpen || cb.failures >= cb.threshold {
            cb.state = Open
        }
        return nil, err
    }

    cb.state = Closed
    cb.failures = 0
    return result, nil
}
```

## Wrapping NATS Request/Reply

```go
cb := circuitbreaker.New(5, 30*time.Second)

func callUserService(nc *nats.Conn, userID string) (User, error) {
    data, err := cb.Execute(func() ([]byte, error) {
        reply, err := nc.Request("svc.users.get",
            mustJSON(map[string]string{"id": userID}),
            2*time.Second)
        return reply.Data, err
    })

    if errors.Is(err, circuitbreaker.ErrOpen) {
        // Circuit is open — use fallback
        return getUserFromCache(userID)
    }
    if err != nil {
        return User{}, err
    }

    var u User
    json.Unmarshal(data, &u)
    return u, nil
}
```

## Using `sony/gobreaker`

```go
import "github.com/sony/gobreaker"

cb := gobreaker.NewCircuitBreaker(gobreaker.Settings{
    Name:        "user-svc",
    MaxRequests: 1,
    Interval:    10 * time.Second,
    Timeout:     30 * time.Second,
    ReadyToTrip: func(counts gobreaker.Counts) bool {
        return counts.ConsecutiveFailures > 5
    },
})

result, err := cb.Execute(func() (interface{}, error) {
    return nc.Request("svc.users.get", req, 2*time.Second)
})
```

---
*Part of the 100-Lesson NATS Series.*
