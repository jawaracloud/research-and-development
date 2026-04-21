# 68 — Troubleshooting Connection Issues

> **Type:** How-To  
> **Phase:** Production & Operations

## Overview

Connection issues are the most common production problems in NATS. This lesson covers how to diagnose and fix them, from authentication failures to network blips.

## 1. Diagnostics Workflow

If a client can't connect:
1. **Can you ping the server?** `nats server ping`.
2. **Is the port open?** `telnet <host> 4222`.
3. **Is it Auth?** Check server logs for `Authorization Violation`.
4. **Is it TLS?** Try connecting with `--insecure` to rule out cert issues.

## 2. Client Side Logging

In Go, use the error handlers to log exactly what's failing:

```go
nc, _ := nats.Connect(url,
    nats.DisconnectErrHandler(func(_ *nats.Conn, err error) {
        log.Printf("Disconnected: %v", err)
    }),
    nats.ReconnectHandler(func(_ *nats.Conn) {
        log.Printf("Reconnected to %s", nc.ConnectedUrl())
    }),
    nats.ClosedHandler(func(_ *nats.Conn) {
        log.Fatalf("Connection closed! Out of retries.")
    }),
)
```

## 3. Common Errors and Fixes

### "nats: no servers available for connection"
- **Cause:** Correct URL? Firewall blocking 4222? Server crashed?
- **Fix:** Verify connectivity with `nats pub` from the same machine.

### "nats: authorization violation"
- **Cause:** Wrong username/password, token, or expired JWT.
- **Fix:** Update client credentials.

### "nats: slow consumer"
- **Cause:** Client is receiving messages faster than it can process them. Server buffer for that client filled up.
- **Fix:** 
    - Increase `PendingLimits()`.
    - Parallelize processing with goroutines.
    - Switch to **Pull Consumers** (JetStream) to control the flow.

### "nats: timeout"
- **Cause:** Request/Reply took longer than the timeout.
- **Fix:** Is the responder alive? Is it processing slowly? High network latency?

## 4. Using `nats server report`

The NATS CLI can pull real-time reports from the server to find problematic clients:

```bash
# Find clients with blocked connections or slow traffic
nats server report connections --sort msgs_to

# Find clients with most subscriptions
nats server report connections --sort subs
```

---
*Part of the 100-Lesson NATS Series.*
