# 36 — Message Deduplication

> **Type:** How-To  
> **Phase:** JetStream

## Overview

JetStream's built-in deduplication prevents the same message from being stored twice within a configurable time window — essential for at-least-once publishers that retry on failure.

## How JetStream Deduplication Works

```
Publisher sends msg with Nats-Msg-Id: "order-abc-123"
JetStream: Not seen before → STORE → return ack (Duplicate: false)

Network blip → publisher retries
Publisher sends msg with Nats-Msg-Id: "order-abc-123"
JetStream: Seen within dedup window → IGNORE → return ack (Duplicate: true)
```

The dedup window (stream `Duplicates` field) is a sliding time window. After expiry, the same ID could be stored again.

## Configuration

```go
js.AddStream(&nats.StreamConfig{
    Name:       "ORDERS",
    Subjects:   []string{"orders.>"},
    Duplicates: 10 * time.Minute,   // remember IDs for 10 minutes
})
```

## Publishing with Deduplication

```go
func safePublish(js nats.JetStreamContext, subject string, data []byte) error {
    // Generate a deterministic, content-addressable ID
    hash := sha256.Sum256(append([]byte(subject+":"), data...))
    msgID := hex.EncodeToString(hash[:16])

    msg := &nats.Msg{Subject: subject, Data: data, Header: nats.Header{}}
    msg.Header.Set(nats.MsgIdHdr, msgID)

    ack, err := js.PublishMsg(msg, nats.MsgId(msgID))  // also sets header via option
    if err != nil {
        return fmt.Errorf("publish: %w", err)
    }

    if ack.Duplicate {
        log.Printf("Duplicate (within window): %s — skipping", msgID)
    }
    return nil
}
```

## Retry-Safe Publisher

```go
func publishWithRetry(js nats.JetStreamContext, subject string, data []byte, msgID string) error {
    msg := &nats.Msg{Subject: subject, Data: data, Header: nats.Header{}}
    msg.Header.Set(nats.MsgIdHdr, msgID)

    for attempt := 1; attempt <= 5; attempt++ {
        ack, err := js.PublishMsg(msg)
        if err == nil {
            if ack.Duplicate {
                return nil  // already stored — success
            }
            log.Printf("Published seq %d", ack.Sequence)
            return nil
        }
        wait := time.Duration(attempt*attempt) * 100 * time.Millisecond
        log.Printf("Attempt %d failed: %v — retrying in %v", attempt, err, wait)
        time.Sleep(wait)
    }
    return fmt.Errorf("failed after 5 attempts")
}
```

## Deduplication ID Strategies

| Strategy | Example | Pros | Cons |
|----------|---------|------|------|
| UUID | `uuid.New().String()` | Unique | Doesn't survive crash (must persist) |
| Business key | `"order-"+orderId` | Deterministic | Requires unique business key |
| Content hash | `sha256(subject+body)` | Automatic dedup | Sensitive to minor body changes |
| Idempotency key | From HTTP request header | Client-controlled | Requires clients to send key |

## Verify Dedup State

```bash
nats stream info ORDERS | grep -i dedup
# Duplicate Window: 10m0s
```

---
*Part of the 100-Lesson NATS Series.*
