# 42 — CQRS with NATS

> **Type:** Tutorial  
> **Phase:** Patterns & Architecture

## What you're building

Implement Command Query Responsibility Segregation (CQRS) using NATS: a write model that publishes events and a read model that subscribes and builds projections.

## Architecture

```
Write Side (Commands)              Read Side (Queries)
─────────────────────              ──────────────────
Client → POST /orders              Client → GET /orders/:id
    ↓                                  ↑
Order Svc → validate               Order Query Svc
    ↓                                  ↑
orders.created (NATS)          subscribe → build projection
                                           (in-memory / Redis / Postgres)
```

## Step 1: Write side — command handler

```go
// order-service/main.go
func createOrderHandler(js nats.JetStreamContext) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        var cmd CreateOrderCommand
        json.NewDecoder(r.Body).Decode(&cmd)

        // Validate command
        if err := validate(cmd); err != nil {
            http.Error(w, err.Error(), http.StatusBadRequest)
            return
        }

        // Build event
        event := OrderCreatedEvent{
            OrderID:   uuid.New().String(),
            UserID:    cmd.UserID,
            Items:     cmd.Items,
            CreatedAt: time.Now().UTC(),
        }
        data, _ := json.Marshal(event)

        // Publish to JetStream
        msg := &nats.Msg{Subject: "orders.created", Data: data, Header: nats.Header{}}
        msg.Header.Set(nats.MsgIdHdr, event.OrderID)
        if _, err := js.PublishMsg(msg); err != nil {
            http.Error(w, "publish failed", http.StatusInternalServerError)
            return
        }

        w.WriteHeader(http.StatusAccepted)
        json.NewEncoder(w).Encode(map[string]string{"orderId": event.OrderID})
    }
}
```

## Step 2: Read side — projection builder

```go
// order-query-service/main.go
type OrderReadModel struct {
    mu     sync.RWMutex
    orders map[string]*OrderView
}

func (m *OrderReadModel) startProjection(js nats.JetStreamContext) {
    js.Subscribe("orders.>",
        func(msg *nats.Msg) {
            switch msg.Subject {
            case "orders.created":
                var ev OrderCreatedEvent
                json.Unmarshal(msg.Data, &ev)
                m.mu.Lock()
                m.orders[ev.OrderID] = &OrderView{
                    ID:     ev.OrderID,
                    Status: "pending",
                    Items:  ev.Items,
                }
                m.mu.Unlock()

            case "orders.cancelled":
                var ev OrderCancelledEvent
                json.Unmarshal(msg.Data, &ev)
                m.mu.Lock()
                if o, ok := m.orders[ev.OrderID]; ok {
                    o.Status = "cancelled"
                }
                m.mu.Unlock()
            }
            msg.Ack()
        },
        nats.Durable("order-projection"),
        nats.DeliverAll(),    // replay full history on startup
        nats.AckExplicit(),
    )
}
```

## Step 3: Query handler

```go
func (m *OrderReadModel) getOrderHandler(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    m.mu.RLock()
    order, ok := m.orders[id]
    m.mu.RUnlock()
    if !ok {
        http.Error(w, "not found", 404)
        return
    }
    json.NewEncoder(w).Encode(order)
}
```

---
*Part of the 100-Lesson NATS Series.*
