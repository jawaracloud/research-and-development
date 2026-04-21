# 86 — Edge Computing with NATS

> **Type:** Explanation  
> **Phase:** Advanced & Real-World

## Overview

Edge computing involves bringing computation and data storage closer to the location where it is needed to improve response times and save bandwidth. NATS is the ideal communication layer for the edge.

## 1. The Challenge of the Edge
- **Intermittent Connectivity:** Edge devices aren't always online.
- **Limited Resources:** Low CPU, RAM, and Disk.
- **Security:** Devices may be physically accessible to unauthorized parties.

## 2. NATS as an Edge Solution
NATS addresses these challenges via:
- **Leaf Nodes:** Standalone servers that act as local hubs.
- **Interest-Based Routing:** Saves bandwidth by only sending what is needed.
- **Embedded NATS:** Libraries like `nats.go` can be embedded directly in small Go binaries for near-zero footprint.

## 3. Pattern: Local Decision Making
Don't send raw data to the cloud for processing. Process it at the edge and send only the result.

```
[Sensor] -> (NATS Local) -> [Local Logic App] -> (NATS Leaf) -> [Cloud Hub]
```
- **Local Logic App:** "If temperature > 50, shut down the machine."
- **Cloud Hub:** "Store 123 reports a high-temp shutdown event."

## 4. Pattern: Content Delivery at the Edge
Use **JetStream Mirrors** to cache static assets or configuration data at the edge.
- **Edge Node:** Mirrors the `CONFIG` stream from the hub.
- **Local Apps:** Read config instantly from the local mirror, even if the hub link is down.

## 5. Security: NKeys for the Edge
Instead of passwords, use **NKeys**. 
- Each edge device generates its own keypair. 
- You only store the *Public Key* on your server.
- This prevents a compromised edge device from leaking globally-useful credentials.

---
*Part of the 100-Lesson NATS Series.*
