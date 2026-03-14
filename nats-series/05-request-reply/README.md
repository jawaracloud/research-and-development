# 05 — Request/Reply Model

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

The **request/reply** pattern in NATS enables synchronous-style communication over an async message bus. It's the ideal replacement for HTTP/REST between internal microservices — same semantics, lower overhead, built-in timeout handling.

## How It Works

```
Requester                     Responder
    │                              │
    │──── Request("users.get") ───▶│
    │     (auto-creates inbox)      │
    │◀─── Reply(user JSON) ────────│
    │                              │
    ▼ (msg received synchronously)
```

NATS automatically creates a unique reply-to inbox subject (`_INBOX.<nonce>`) for each request, routed back to the caller.

## Go Implementation

```go
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "time"

    "github.com/nats-io/nats.go"
)

type UserRequest struct{ ID string }
type UserResponse struct{ Name, Email string }

func main() {
    nc, _ := nats.Connect(nats.DefaultURL)
    defer nc.Drain()

    // ── Responder (server side) ──────────────────────────────
    nc.Subscribe("users.get", func(msg *nats.Msg) {
        var req UserRequest
        json.Unmarshal(msg.Data, &req)

        resp, _ := json.Marshal(UserResponse{
            Name:  "Alice",
            Email: "alice@example.com",
        })
        msg.Respond(resp)  // sends to msg.Reply inbox
    })

    // ── Requester (client side) ──────────────────────────────
    req, _ := json.Marshal(UserRequest{ID: "u-001"})
    reply, err := nc.Request("users.get", req, 2*time.Second)
    if err != nil {
        log.Fatal("timeout or no responder:", err)
    }

    var user UserResponse
    json.Unmarshal(reply.Data, &user)
    fmt.Printf("Got user: %s <%s>\n", user.Name, user.Email)
}
```

## Scatter/Gather (fan-out requests)

Request multiple responders and collect replies:

```go
// Subscribe to wildcard inbox
inbox := nats.NewInbox()
sub, _ := nc.SubscribeSync(inbox)
nc.PublishRequest("workers.status", inbox, nil)

// Gather responses for 500ms
results := []string{}
deadline := time.Now().Add(500 * time.Millisecond)
for time.Now().Before(deadline) {
    msg, err := sub.NextMsg(time.Until(deadline))
    if err != nil { break }
    results = append(results, string(msg.Data))
}
fmt.Printf("Got %d responses\n", len(results))
```

## Request/Reply vs HTTP

| Aspect | HTTP | NATS Request/Reply |
|--------|------|--------------------|
| Discovery | DNS + LB | Subject-based auto-routing |
| Protocol | HTTP/1.1 or HTTP/2 | NATS (TCP, 2–5 bytes overhead) |
| Timeout | Client-side | Built-in (`nc.Request` timeout param) |
| Fan-out | No | Yes (scatter/gather) |
| Load balancing | External LB | Queue Groups (lesson 06) |

## Error handling

```go
reply, err := nc.Request("users.get", req, 2*time.Second)
switch {
case errors.Is(err, nats.ErrNoResponders):
    // no service listening on that subject
case errors.Is(err, nats.ErrTimeout):
    // service didn't respond within 2s
}
```

---
*Part of the 100-Lesson NATS Series.*
