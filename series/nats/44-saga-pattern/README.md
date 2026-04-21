# 44 — Saga Pattern

> **Type:** Tutorial  
> **Phase:** Patterns & Architecture

## What you're building

Implement a distributed saga (long-running transaction) across multiple services using NATS JetStream — with coordinated compensation on failure.

## The Problem

A checkout flow spans 3 services:
```
1. reserve inventory
2. charge payment
3. confirm order

If step 2 fails → must undo step 1 (compensation)
```

Without sagas, a failed step 2 leaves orphaned inventory reservations.

## Saga Orchestrator Pattern

A central orchestrator drives each step and runs compensations on failure:

```go
// saga-orchestrator/main.go

type CheckoutSaga struct {
    OrderID string
    State   string  // "started", "inventory-reserved", "paid", "confirmed", "failed"
}

func (s *CheckoutSaga) Run(js nats.JetStreamContext, nc *nats.Conn) error {
    // Step 1: Reserve inventory
    reply, err := nc.Request("inventory.reserve",
        mustJSON(map[string]string{"orderId": s.OrderID}), 5*time.Second)
    if err != nil || isError(reply) {
        return s.fail(js, "inventory-reserve", nil)
    }
    s.State = "inventory-reserved"

    // Step 2: Charge payment
    reply, err = nc.Request("payments.charge",
        mustJSON(map[string]string{"orderId": s.OrderID}), 10*time.Second)
    if err != nil || isError(reply) {
        // Compensate step 1
        nc.Publish("inventory.release",
            mustJSON(map[string]string{"orderId": s.OrderID}))
        return s.fail(js, "payment-charge", nil)
    }
    s.State = "paid"

    // Step 3: Confirm order
    js.Publish("orders.confirmed",
        mustJSON(map[string]string{"orderId": s.OrderID, "state": "confirmed"}))
    s.State = "confirmed"
    return nil
}

func (s *CheckoutSaga) fail(js nats.JetStreamContext, step string, compensations []string) error {
    s.State = "failed"
    js.Publish("orders.failed",
        mustJSON(map[string]string{"orderId": s.OrderID, "failedStep": step}))
    return fmt.Errorf("saga failed at %s", step)
}
```

## Saga Choreography (no orchestrator)

Each service publishes success/failure events and other services react:

```
Order Svc:       orders.created → 
Inventory Svc:   orders.inventory-reserved | orders.inventory-failed →
Payment Svc:     orders.paid | orders.payment-failed →
Confirmation:    orders.confirmed | orders.compensation-needed →
Inventory Svc:   (on compensation-needed) → releases reservation
```

## Saga State Persistence

```go
// Persist saga state in NATS KV
kv, _ := js.KeyValue("sagas")

func saveSagaState(kv nats.KeyValue, s *CheckoutSaga) {
    data, _ := json.Marshal(s)
    kv.Put(s.OrderID, data)
}

func loadSagaState(kv nats.KeyValue, orderID string) (*CheckoutSaga, error) {
    entry, err := kv.Get(orderID)
    if err != nil { return nil, err }
    var s CheckoutSaga
    json.Unmarshal(entry.Value(), &s)
    return &s, nil
}
```

## Key Properties

| | Orchestration | Choreography |
|-|--------------|-------------|
| **Traceability** | Easy (central log) | Hard (distributed) |
| **Coupling** | Orchestrator knows all | Services only know events |
| **Complexity** | Centralised | Distributed |
| **Failure handling** | Explicit in orchestrator | Each service responsible |

---
*Part of the 100-Lesson NATS Series.*
