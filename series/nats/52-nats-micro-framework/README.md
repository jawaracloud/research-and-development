# 52 — NATS Micro Services Framework

> **Type:** Tutorial  
> **Phase:** Patterns & Architecture

## What you're building

Build a production-grade microservice using the NATS Micro framework (`nats.go/micro`) — with service discovery, health checks, stats, and multi-endpoint routing built in.

## What NATS Micro Provides

- Service registration on NATS with metadata
- Automatic `$SRV.INFO`, `$SRV.PING`, `$SRV.STATS` endpoints
- Multi-endpoint routing within one service
- Error handling with status codes
- Built-in stats: requests, errors, processing time

## Step 1: Order Service

```go
package main

import (
    "encoding/json"
    "log"

    "github.com/nats-io/nats.go"
    "github.com/nats-io/nats.go/micro"
)

func main() {
    nc, _ := nats.Connect(nats.DefaultURL)
    defer nc.Drain()

    svc, err := micro.AddService(nc, micro.Config{
        Name:        "order-svc",
        Version:     "1.0.0",
        Description: "Order management service",
        Metadata: map[string]string{
            "region": "us-east-1",
            "team":   "platform",
        },
    })
    if err != nil { log.Fatal(err) }

    // Add endpoint group
    orders := svc.AddGroup("orders")

    orders.AddEndpoint("create",
        micro.HandlerFunc(createOrder),
        micro.WithEndpointMetadata(map[string]string{"doc": "Create a new order"}),
    )

    orders.AddEndpoint("get",
        micro.HandlerFunc(getOrder),
    )

    orders.AddEndpoint("cancel",
        micro.HandlerFunc(cancelOrder),
    )

    log.Println("Order service started")
    select {}   // block
}

func createOrder(req micro.Request) {
    var cmd struct {
        UserID string  `json:"userId"`
        Items  []Item  `json:"items"`
    }
    if err := json.Unmarshal(req.Data(), &cmd); err != nil {
        req.Error("400", "invalid request: "+err.Error(), nil)
        return
    }

    orderID := createOrderInDB(cmd)
    res, _ := json.Marshal(map[string]string{"orderId": orderID})
    req.Respond(res)
}

func getOrder(req micro.Request) {
    var q struct{ ID string `json:"id"` }
    json.Unmarshal(req.Data(), &q)

    order := getOrderFromDB(q.ID)
    if order == nil {
        req.Error("404", "order not found", nil)
        return
    }
    res, _ := json.Marshal(order)
    req.Respond(res)
}
```

## Step 2: Client Usage

```go
// Subject auto-generated: orders-svc.orders.create
reply, err := nc.Request("order-svc.orders.create",
    mustJSON(CreateOrderCmd{UserID: "u-1", Items: items}),
    5*time.Second)
```

## Step 3: Service Discovery CLI

```bash
# List all registered services
nats micro ls

# Ping all instances of order-svc
nats micro ping order-svc

# View stats
nats micro stats order-svc

# Service info
nats micro info order-svc
```

---
*Part of the 100-Lesson NATS Series.*
