# 71 — Security Hardening

> **Type:** How-To  
> **Phase:** Production & Operations

## Overview

Moving NATS from development to production requires locking down the system. This lesson provides a checklist for security hardening your servers.

## 1. Disable Default Listeners
Never leave the server listening on public interfaces without authentication.

- `listen: "127.0.0.1:4222"` (Local only)
- OR `listen: "0.0.0.0:4222"` WITH mandatory TLS/Auth.

## 2. Mandatory TLS
Enforce encryption for all clients and cluster routes.

```
tls {
  cert_file: "/etc/nats/server-cert.pem"
  key_file:  "/etc/nats/server-key.pem"
  ca_file:   "/etc/nats/ca.pem"
  verify:    true  # Require client certificates (mTLS)
}
```

## 3. Account-Based Isolation (RBAC)
Never use a single "admin" user for everything. Create dedicated accounts per service/app.

## 4. Resource Limits
Prevent Denial of Service (DoS) by limiting what a single client can do.

```
# server.conf
max_payload: 1MB
max_connections: 50000
max_control_line: 1024
```

## 5. Network Access Control (Firewalling)
- **Port 4222:** Clients only.
- **Port 6222:** Cluster peers ONLY. (Drop all other traffic).
- **Port 8222:** Monitoring ONLY. (Keep this internal).
- **Port 7422:** Leafnode remotes ONLY.

## 6. Securing the System Account
The `$SYS` account has visibility into everything. It MUST be secured with NKeys/JWT.

## 7. Configuration Security
- Keep credentials (creds/keys) in a secure secret manager (e.g., HashiCorp Vault).
- Use environment variables for sensitive paths in the config.

---
*Part of the 100-Lesson NATS Series.*
