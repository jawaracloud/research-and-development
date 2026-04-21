# 39 — Stream Purge & Delete

> **Type:** How-To  
> **Phase:** JetStream

## Overview

Managing stream data lifecycle — purging messages while keeping the stream, deleting individual messages, and deleting entire streams — is essential for data governance and storage management.

## Purge: Remove All Messages

Purge deletes all messages from a stream but keeps the stream definition and consumers:

```go
js, _ := nc.JetStream()

// Purge all messages
err := js.PurgeStream("ORDERS")
if err != nil {
    log.Fatal(err)
}
log.Println("Stream purged — 0 messages, stream retained")
```

```bash
nats stream purge ORDERS      # interactive confirmation
nats stream purge ORDERS -f   # force (no prompt)
```

## Purge by Subject

Purge only messages matching a specific subject filter:

```go
js.PurgeStream("ORDERS", &nats.StreamPurgeRequest{
    Filter: "orders.cancelled",   // only purge cancelled orders
})
```

```bash
nats stream purge ORDERS --subject "orders.cancelled"
```

## Purge by Sequence

Keep only the N most recent messages:

```go
js.PurgeStream("ORDERS", &nats.StreamPurgeRequest{
    Keep: 1000,   // retain last 1000 messages
})
```

Or purge everything up to a sequence number:

```go
js.PurgeStream("ORDERS", &nats.StreamPurgeRequest{
    Sequence: 5000,   // purge all messages with seq < 5000
})
```

## Delete a Specific Message

Delete one message by its sequence number (leaves a gap — seq is not reused):

```go
err := js.DeleteMsg("ORDERS", 42)
if err != nil {
    log.Printf("delete msg: %v", err)
}
```

```bash
nats stream rmm ORDERS 42
```

## Delete the Entire Stream

```go
err := js.DeleteStream("ORDERS")
if err != nil {
    log.Fatal(err)
}
```

```bash
nats stream rm ORDERS
```

⚠️ This permanently deletes the stream AND all consumers and their cursor positions.

## Scheduled Purge Pattern

Use a cron-like scheduler to purge old messages on a schedule:

```go
// Purge daily at midnight — keep last 7 days via MaxAge instead,
// or explicitly purge if you need more control:
func scheduledPurge(js nats.JetStreamContext) {
    ticker := time.NewTicker(24 * time.Hour)
    for range ticker.C {
        cutoff := time.Now().Add(-7 * 24 * time.Hour)
        info, _ := js.StreamInfo("LOGS")
        for seq := info.State.FirstSeq; seq < info.State.LastSeq; seq++ {
            msg, _ := js.GetMsg("LOGS", seq)
            if msg.Time.Before(cutoff) {
                js.DeleteMsg("LOGS", seq)
            }
        }
    }
}
```

Better: just set `MaxAge` on the stream and let JetStream handle it automatically.

---
*Part of the 100-Lesson NATS Series.*
