# 92 — Large File Transfers

> **Type:** How-To  
> **Phase:** Advanced & Real-World

## Overview

Transferring very large files (GBs+) over NATS requires a different strategy than standard messages. This lesson covers using the **Object Store** and parallelizing reads.

## 1. Object Store (The Preferred Way)

As seen in Lesson 88, the Object Store automatically handles chunking and reassembly.

```bash
# Push a 5GB ISO
nats object put IMAGES my-big-file.iso

# Pull it back
nats object get IMAGES my-big-file.iso
```

## 2. Resumable Transfers

If a file transfer is interrupted:
- NATS Object Store checks which chunks are already in the stream.
- It only uploads/downloads the missing chunks.
- **Benefit:** Highly resilient over unstable 4G/Satellite links.

## 3. Parallel Downloads

For maximum speed, you can range-read multiple chunks in parallel.

```go
// Pseudo-code for parallel read
go func() { readRange(0, 100) }()
go func() { readRange(101, 200) }()
// Combine result
```

## 4. Message-Based "Small" Large Files

If your file is < 10MB, you might be tempted to use standard messages.
- **DON'T:** It bloats the NATS server memory and can cause slow-consumer drops.
- **DO:** Use Object Store for anything over 1MB.

## 5. Cleaning Up

Large files consume significant JetStream storage.
- Set **TTL** on your Object Store buckets to automatically delete temporary transfer files.
- `nats object rm BUCKET NAME` to delete once the recipient confirms receiving.

---
*Part of the 100-Lesson NATS Series.*
