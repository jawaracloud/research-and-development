# 93 — Security Auditing

> **Type:** How-To  
> **Phase:** Advanced & Real-World

## Overview

In highly regulated environments, you must prove who did what and when. This lesson covers auditing your NATS cluster.

## 1. Authentication Auditing

Monitor the NATS log for authentication attempts.
- **Success:** `[INF] Client authenticated: [user:app_1]`
- **Failure:** `[ERR] Authorization violation for user:attacker_1`

**Tip:** Feed these logs into a SIEM (Splunk, ELK) to alert on brute force attempts.

## 2. Configuration Auditing

If using **NSC**, every change to accounts or users is stored as a signed JWT.
- You can keep your `nsc` data directory in **Git**.
- Every `git commit` represents an audited change to your cluster security.

## 3. Message Auditing (Shadowing)

To audit the *data* moving through the system, use a silent side-car subscriber.

```go
// Auditor service
nc.Subscribe(">", func(msg *nats.Msg) {
    // Record message metadata and hash to an audit DB
    auditLog(msg.Subject, msg.Header, sha256(msg.Data))
})
```
*Note: Ensure the auditor has permissions to read all subjects.*

## 4. JetStream State Auditing

Periodically dump the state of your streams to verify integrity.

```bash
nats stream report > audit_report_$(date +%F).txt
```

## 5. Access Reviews

Quarterly check:
1. Are there old users that should be deleted?
2. Are any clients using insecure (non-TLS) connections?
3. Are anyone's ACLs too broad (e.g., `allow: [">"]`)?

---
*Part of the 100-Lesson NATS Series.*
