# 94 — Compliance (GDPR/HIPAA) in EDA

> **Type:** Explanation  
> **Phase:** Advanced & Real-World

## Overview

Event-Driven Architectures (EDA) present unique compliance challenges, especially regarding the "Right to be Forgotten" (GDPR) or data privacy (HIPAA).

## 1. The Challenge of Immutability

NATS JetStream is designed to be an immutable log. But GDPR says users can request their data be deleted.
- **Solution:** Don't store PII (Personally Identifiable Information) in plain text in a stream.

## 2. Pattern: Crypto-Shredding

Instead of deleting the message from the stream, you delete the **Encryption Key**.

1. Generate a unique `Key_A` for `User_A`.
2. Encrypt `User_A`'s data before publishing to NATS.
3. User requests deletion → **Delete `Key_A`** from your key manager.
4. Result: The data remains in the NATS stream but is now unreadable ciphertext forever.

## 3. Pattern: Message Deletion

JetStream *does* allow deleting specific messages by sequence, but it's expensive and leaves "holes" in the log. Use this only for extreme cases.

```bash
nats stream rmm ORDERS 12345
```

## 4. Data Residency

HIPAA or national laws might require data to stay in a specific region.
- Use **Accounts** and **Placement Tags** (Lesson 89) to ensure encrypted messages are only stored on servers physically located in a compliant region.

## 5. Retention Management

Always set a `MaxAge` on streams containing user data.
- "We only keep order history in NATS for 2 years." 
- This automatically complies with data minimization requirements.

## 6. Access Control and Logging

- Use **mTLS** (Lesson 15) to ensure only authorized services can even connect.
- Use **Audit Logs** (Lesson 93) to prove that no unauthorized actor viewed protected data.

---
*Part of the 100-Lesson NATS Series.*
