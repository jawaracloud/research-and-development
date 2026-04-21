# 18 — Message Headers

> **Type:** How-To  
> **Phase:** Foundations

## Overview

NATS message headers (added in NATS 2.2) allow attaching arbitrary key-value metadata to messages — useful for tracing, content-type negotiation, routing hints, and message versioning.

## Publishing with Headers

```go
package main

import (
    "fmt"
    "github.com/nats-io/nats.go"
)

func main() {
    nc, _ := nats.Connect(nats.DefaultURL)
    defer nc.Drain()

    // Build message with headers
    msg := &nats.Msg{
        Subject: "orders.created",
        Data:    []byte(`{"id":"abc-123","amount":99.99}`),
        Header:  nats.Header{},
    }

    // Standard headers
    msg.Header.Set("Content-Type", "application/json")
    msg.Header.Set("Schema-Version", "v2")
    msg.Header.Set("X-Correlation-ID", "req-789-xyz")
    msg.Header.Set("X-Source-Service", "order-svc")
    msg.Header.Add("X-Tag", "priority")    // Add supports multiple values

    nc.PublishMsg(msg)
    fmt.Println("Published with headers")
}
```

## Subscribing and Reading Headers

```go
nc.Subscribe("orders.created", func(msg *nats.Msg) {
    // Read headers
    contentType := msg.Header.Get("Content-Type")
    correlationID := msg.Header.Get("X-Correlation-ID")
    schemaVer := msg.Header.Get("Schema-Version")

    fmt.Printf("Content-Type: %s\n", contentType)
    fmt.Printf("Correlation-ID: %s\n", correlationID)
    fmt.Printf("Schema: %s\n", schemaVer)
    fmt.Printf("Body: %s\n", msg.Data)
})
```

## Common Header Conventions

| Header | Purpose | Example |
|--------|---------|---------|
| `Content-Type` | Payload format | `application/json` |
| `Schema-Version` | Schema evolution | `v2` |
| `X-Correlation-ID` | Distributed tracing | UUID |
| `X-Source-Service` | Audit trail | `order-svc` |
| `X-Idempotency-Key` | Deduplication key | `order-abc-attempt-1` |
| `Nats-Msg-Id` | JetStream dedup ID | unique string |
| `X-Retry-Count` | Retry tracking | `3` |

## JetStream — `Nats-Msg-Id` for Deduplication

```go
js, _ := nc.JetStream()

msg := &nats.Msg{
    Subject: "orders.created",
    Data:    data,
    Header:  nats.Header{},
}
// This ID prevents the same message from being stored twice
// in a stream (idempotent publish) within the dedup window
msg.Header.Set(nats.MsgIdHdr, "order-abc-123-v1")

ack, _ := js.PublishMsg(msg)
fmt.Printf("Seq: %d, Duplicate: %v\n", ack.Sequence, ack.Duplicate)
```

## Headers-Only Messages

Subscribe while ignoring the body payload — useful for lightweight control messages:

```go
// Server: advertise capability (body irrelevant)
nc.Publish("workers.ready", nil)   // headers-only

// Consumer: filter by header
nc.Subscribe("workers.>", func(msg *nats.Msg) {
    if msg.Header.Get("X-Work-Type") == "batch" {
        // handle batch work
    }
})
```

---
*Part of the 100-Lesson NATS Series.*
