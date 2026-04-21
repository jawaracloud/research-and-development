# 77 — Upgrading NATS Clusters

> **Type:** How-To  
> **Phase:** Production & Operations

## Overview

Upgrading NATS is designed to be a zero-downtime operation. This lesson covers the best practices for performing rolling upgrades in a production cluster.

## 1. Compatibility Check
- Check the [NATS Release Notes](https://github.com/nats-io/nats-server/releases) for breaking changes.
- **Rule of Thumb:** Minor versions (e.g., 2.9 to 2.10) are backward compatible.

## 2. Rolling Upgrade Procedure (Standard)

1. **Pick the First Node.**
2. **Stop the node.**
3. **Update the binary/image.**
4. **Restart the node.**
5. **Verify Health:** Wait for it to rejoin the cluster and catch up on any Raft logs.
6. **Repeat** for remaining nodes.

## 3. Kubernetes / Helm Upgrade

If using the official Helm chart, it's a single command:

```bash
helm upgrade nats nats/nats \
  --set image.tag=2.10.12 \
  --reuse-values
```
Kubernetes will handle the `RollingUpdate`, waiting for each pod to be `Ready` before moving to the next.

## 4. JetStream Considerations

When a JetStream leader node reboots, the cluster will automatically hold a new election.
- **Tip:** To speed up the process, you can manually "Step Down" the leader before stopping the node.

```bash
nats stream cluster step-down ORDERS
```

## 5. Client Impact

- Clients will experience a momentary disconnect and automatically reconnect to another node in the cluster seamlessly. 
- **Important:** Ensure your client `MaxReconnects` is high enough or set to -1.

## 6. Rollback Plan
Always have a rollback plan.
- If Node 1 fails after upgrade, immediately revert it to the previous version before touching Node 2.
- **Note:** Downgrading and then re-upgrading is safe as long as the data format hasn't changed (which is rare in NATS).

---
*Part of the 100-Lesson NATS Series.*
