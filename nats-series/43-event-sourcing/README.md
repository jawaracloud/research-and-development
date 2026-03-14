# 43 — Event Sourcing with JetStream

> **Type:** Tutorial  
> **Phase:** Patterns & Architecture

## What you're building

Use JetStream as an event store — a system where the source of truth is a log of events, and the current state is always derived by replaying those events.

## Event Sourcing Principles

```
Traditional DB:   store CURRENT STATE only
Event Sourcing:   store EVENTS (state changes) → derive current state on demand

ORDER table: {status: "shipped"}    ← state only
                    vs
Event log:
  orders.created   {orderId: "abc"}
  orders.paid      {orderId: "abc", amount: 99}
  orders.shipped   {orderId: "abc", trackingNo: "TRK123"}
  → replay these 3 events to derive: {status: "shipped", ...}
```

## Step 1: Design the event schema

```go
type Event struct {
    Type      string          `json:"type"`
    AggID     string          `json:"aggId"`   // aggregate ID (e.g., orderId)
    Version   int             `json:"version"`
    Timestamp time.Time       `json:"ts"`
    Data      json.RawMessage `json:"data"`
}
```

## Step 2: Append-only event store

```go
func appendEvent(js nats.JetStreamContext, aggID string, eventType string, data interface{}) error {
    payload, _ := json.Marshal(data)
    event := Event{
        Type:      eventType,
        AggID:     aggID,
        Timestamp: time.Now().UTC(),
        Data:      payload,
    }
    body, _ := json.Marshal(event)

    msg := &nats.Msg{
        Subject: fmt.Sprintf("events.order.%s", aggID),
        Data:    body,
        Header:  nats.Header{},
    }
    msg.Header.Set(nats.MsgIdHdr, fmt.Sprintf("%s-%s-%d", aggID, eventType, time.Now().UnixNano()))

    _, err := js.PublishMsg(msg)
    return err
}

// Usage
appendEvent(js, "order-abc", "OrderCreated", OrderCreatedData{...})
appendEvent(js, "order-abc", "OrderPaid", OrderPaidData{Amount: 99})
appendEvent(js, "order-abc", "OrderShipped", OrderShippedData{TrackingNo: "TRK123"})
```

## Step 3: Rehydrate aggregate from events

```go
type OrderAggregate struct {
    ID       string
    Status   string
    Amount   float64
    Tracking string
    Version  int
}

func (o *OrderAggregate) Apply(event Event) {
    o.Version++
    switch event.Type {
    case "OrderCreated":
        o.Status = "pending"
    case "OrderPaid":
        var d struct{ Amount float64 }
        json.Unmarshal(event.Data, &d)
        o.Amount = d.Amount
        o.Status = "paid"
    case "OrderShipped":
        var d struct{ TrackingNo string }
        json.Unmarshal(event.Data, &d)
        o.Tracking = d.TrackingNo
        o.Status = "shipped"
    }
}

func rehydrate(js nats.JetStreamContext, orderID string) (*OrderAggregate, error) {
    sub, _ := js.SubscribeSync(
        fmt.Sprintf("events.order.%s", orderID),
        nats.OrderedConsumer(), nats.DeliverAll(),
        nats.BindStream("EVENTS"),
    )
    defer sub.Drain()

    agg := &OrderAggregate{ID: orderID}
    for {
        msg, err := sub.NextMsg(500 * time.Millisecond)
        if err != nil { break }
        var ev Event
        json.Unmarshal(msg.Data, &ev)
        agg.Apply(ev)
    }
    return agg, nil
}
```

---
*Part of the 100-Lesson NATS Series.*
