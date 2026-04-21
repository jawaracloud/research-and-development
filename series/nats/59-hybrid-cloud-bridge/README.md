# 59 — Hybrid Cloud Bridge (Leaf Nodes)

> **Type:** Tutorial  
> **Phase:** Patterns & Architecture

## What you're building

Configure a **Leaf Node** connection to bridge a local/on-prem NATS server to a central cloud NATS cluster, enabling secure, unidirectional or bidirectional messaging across networks.

## Architecture

```
[On-Premises / Edge]               [Cloud Hub]
nats-server A (Leaf) --- TLS ----> nats-server B (Hub)
```

- **Leaf Server:** Connects *outbound* to the hub.
- **Security:** No inbound firewall ports needs to be open on-prem.
- **Account Mapping:** Local messages can be mapped to cloud-specific subjects.

## Step 1: Cloud Hub Configuration

`hub.conf`:
```
leafnodes {
    port: 7422
    listen: "0.0.0.0:7422"
}
```

## Step 2: Leaf Node Configuration

`leaf.conf`:
```
leafnodes {
    remotes [
        {
            url: "nats://cloud-hub:7422"
            # Optional: Credentials for the cloud account
            # credentials: "/path/to/my.creds"
        }
    ]
}
```

## Step 3: Deployment & Verification

Start both servers. Any message published on the leaf server to a shared subject will be visible on the cloud hub (and vice-versa, depending on permissions).

```bash
# On Cloud Hub
nats sub "orders.>"

# On Leaf Node
nats pub "orders.new" "local-event"
```

## Advanced: Scoped Subjects

Map local subjects to a prefix in the cloud to prevent collisions:

```
# leaf.conf
leafnodes {
    remotes [
        {
            url: "nats://cloud-hub:7422"
            account: "APP_ACCOUNT"
            local_account: "LOCAL"
        }
    ]
}
```

## Use Case: Factory Edge

- **Factory Floor:** NATS runs locally. PLCs and robots publish metrics.
- **Disconnected Mode:** If the internet fails, the factory keeps running locally.
- **Sync:** When reconnected, Leaf Node automatically syncs JetStream mirrors and forwards ad-hoc messages.

---
*Part of the 100-Lesson NATS Series.*
