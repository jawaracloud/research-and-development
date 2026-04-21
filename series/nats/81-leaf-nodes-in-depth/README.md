# 81 — Leaf Nodes in Depth

> **Type:** Tutorial  
> **Phase:** Advanced & Real-World

## What you're building

Learn how to use **Leaf Nodes** to connect edge environments (IoT, retail stores, local data centers) to a central NATS cluster with autonomous operation and subject remapping.

## 1. Why Leaf Nodes?

Leaf nodes are distinct from standard cluster nodes:
- **Autonomous:** If the link to the core fails, the leaf node continues to handle local traffic.
- **Topological:** They allow building a "hub-and-spoke" model.
- **Privacy:** You can control exactly which subjects are exported to the hub.

## 2. Advanced Configuration: Remapping

You can remap subjects so that local traffic from many leaf nodes doesn't collide in the central hub.

`leaf-node-1.conf`:
```
leafnodes {
    remotes [
        {
            url: "nats://hub:7422"
            account: "CORP"
            # Map local "orders" to "hub.store-1.orders"
            subject_transforms: [
              { src: "orders.>", dest: "hub.store-1.orders.>" }
            ]
        }
    ]
}
```

## 3. JetStream on the Edge

You can run JetStream locally on a leaf node.

- **Local Persistence:** Store telemetry data locally.
- **Background Sync:** Use a **Mirror** on the hub to pull data from the leaf node when the connection is healthy.

```go
// On Central Hub
js.AddStream(&nats.StreamConfig{
    Name: "STORE_1_MIRROR",
    Mirror: &nats.StreamSource{
        Name: "ORDERS",
        External: &nats.ExternalStream{ APIPrefix: "$JS.store-1.API" },
    },
})
```

## 4. Multi-Account Leaf Nodes

A single leaf node can connect several local accounts to different accounts on the hub, maintaining isolation all the way from edge to cloud.

## 5. Use Case: Offline-First Retail
- **Store System:** Registers, inventory, and kiosks talk to the local leaf node.
- **Internet Outage:** The store keeps selling. Data is stored in the local JetStream.
- **Recovery:** When internet is back, the leaf node "drains" its accumulated messages to the cloud headquarters seamlessly.

---
*Part of the 100-Lesson NATS Series.*
