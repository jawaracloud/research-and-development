# 49 — Idempotent Consumers

> **Type:** How-To  
> **Phase:** Patterns & Architecture

## Overview

An idempotent consumer produces the same outcome regardless of how many times it receives the same message. This is the other half of exactly-once processing (lesson 35), and critical for resilient systems.

## Why Consumers Receive Duplicate Messages

1. **Consumer crash** before ack → JetStream redelivers after `AckWait`
2. **Network interruption** → ack lost in transit → redeliver
3. **Slow consumer** → `AckWait` expires → redeliver
4. **Explicit Nak** → redelivery requested

## Strategy 1: Database Idempotency Key

```go
func processOrderIdempotent(db *sql.DB, msg *nats.Msg) error {
    var order Order
    json.Unmarshal(msg.Data, &order)

    _, err := db.Exec(`
        INSERT INTO orders (id, user_id, amount, status)
        VALUES ($1, $2, $3, 'pending')
        ON CONFLICT (id) DO NOTHING
    `, order.ID, order.UserID, order.Amount)

    // ON CONFLICT DO NOTHING = safe to call multiple times with same order.ID
    return err
}
```

## Strategy 2: Redis SET NX (set if not exists)

```go
func processWithRedis(rdb *redis.Client, msg *nats.Msg) error {
    msgID := msg.Header.Get(nats.MsgIdHdr)
    key := "processed:" + msgID

    // Try to claim the message
    set, err := rdb.SetNX(context.Background(), key, "1", 24*time.Hour).Result()
    if err != nil { return err }
    if !set {
        // Already processed — skip
        return nil
    }

    // Process (exactly once)
    return doWork(msg.Data)
}
```

## Strategy 3: Sequence-Based State Machine

```go
type OrderState struct {
    ID              string
    LastEventVersion int
}

func applyEvent(db *sql.DB, orderID string, version int, applyFn func() error) error {
    tx, _ := db.Begin()

    var current int
    tx.QueryRow("SELECT version FROM orders WHERE id=$1 FOR UPDATE", orderID).Scan(&current)

    if current >= version {
        tx.Rollback()
        return nil   // already applied this version — idempotent skip
    }

    if err := applyFn(); err != nil {
        tx.Rollback()
        return err
    }

    tx.Exec("UPDATE orders SET version=$1 WHERE id=$2", version, orderID)
    return tx.Commit()
}
```

## Strategy 4: Natural Idempotency

Design operations that are inherently idempotent:

```go
// SET (not INCREMENT) — idempotent
db.Exec("UPDATE inventory SET quantity=$1 WHERE sku=$2", newQty, sku)

// Upsert — idempotent
db.Exec("INSERT INTO sessions (...) ON CONFLICT (token) DO UPDATE SET expires=$1", expires)

// Avoid: db.Exec("UPDATE inventory SET quantity = quantity - $1 WHERE sku=$2", qty, sku)
// ↑ NOT idempotent — applying twice deducts twice
```

## Tests

```go
func TestIdempotency(t *testing.T) {
    msg := buildOrderMsg("order-test-123")

    // Process once
    require.NoError(t, processOrder(db, msg))

    // Process same message again — should succeed with same result
    require.NoError(t, processOrder(db, msg))

    // Verify only one record in DB
    var count int
    db.QueryRow("SELECT COUNT(*) FROM orders WHERE id='order-test-123'").Scan(&count)
    require.Equal(t, 1, count)
}
```

---
*Part of the 100-Lesson NATS Series.*
