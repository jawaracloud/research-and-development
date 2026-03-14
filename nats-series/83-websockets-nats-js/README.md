# 83 — WebSockets & NATS.js

> **Type:** Tutorial  
> **Phase:** Advanced & Real-World

## What you're building

Connect a web browser directly to your NATS cluster using WebSockets and the `nats.js` library, enabling real-time dashboards and live updates.

## 1. Server Configuration (WebSocket)

`server.conf`:
```
websocket {
    port: 8080
    no_tls: true  # Use only for dev! In prod, use TLS.
}
```

## 2. Connecting from the Browser

```javascript
import { connect, StringCodec } from "nats.ws";

async function run() {
    const sc = StringCodec();
    const nc = await connect({ servers: "ws://localhost:8080" });
    console.log("Connected to NATS via WebSockets!");

    const sub = nc.subscribe("updates.>");
    (async () => {
        for await (const m of sub) {
            console.log(`[${m.subject}] ${sc.decode(m.data)}`);
            // Update your UI here
        }
    })();
}
```

## 3. JetStream in the Browser

`nats.js` supports JetStream! You can create ephemeral or durable consumers directly in the client.

```javascript
const js = nc.jetstream();
const sub = await js.subscribe("orders.>", {
    durable_name: "web-client-1",
    deliver_all: true
});
```

## 4. Security Considerations

- **DO NOT** use default accounts for browser clients.
- **Authentication:** Use **NATS Accounts** and JWTs to restrict browser clients to safe, read-only subjects.
- **WSS:** Always use Secure WebSockets (`wss://`) in production to encrypt traffic.

## 5. Use Case: Live Logistics Map
- **Backend:** Ships and trucks publish their GPS coordinates to NATS.
- **Frontend:** A React app connects via WebSockets and updates icons on a map instantly as NATS messages arrive.

---
*Part of the 100-Lesson NATS Series.*
