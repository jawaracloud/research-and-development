# 91 — Streaming Video over NATS

> **Type:** Tutorial  
> **Phase:** Advanced & Real-World

## What you're building

Learn how to stream live video data over NATS by chunking frames and using JetStream to handle buffering and player synchronization.

## 1. Why NATS for Video?
- **Low Latency:** Perfect for tele-operation or live dashboards.
- **Fan-Out:** One camera stream can be viewed by many clients simultaneously.
- **Buffer Management:** JetStream `MaxAge` or `MaxMsgs` acts as a sliding window buffer.

## 2. The Chunking Strategy

Standard video frames (especially 4K) are too large for a single NATS message.
- **Solution:** Partition the video into chunks (MPEG-TS or raw frames) under 1MB.

## 3. Producer (Camera Side)

```go
// Simplified Go producer
for frame := range camera.Capture() {
    nc.Publish("video.stream.01", frame)
    // Optional: add timestamp/seq in headers for re-assembly
}
```

## 4. Consumer (Player Side)

Use a **JetStream Ordered Consumer** to ensure frames arrive in the exact order they were sent.

```javascript
// nats.js client in a browser
const sub = await js.subscribe("video.stream.01", {
    ordered: true,
    deliver_new: true
});

for await (const m of sub) {
    displayFrame(m.data);
}
```

## 5. Handling Latency (Tuning)

- **Use Core NATS (no JetStream):** For ultra-low latency "live" only mode where dropped frames are preferred over delayed ones.
- **Memory Storage:** If using JetStream, use `MemoryStorage` for the video stream to avoid disk IO jitter.

## 6. Use Case: Security System
- **Hub:** Collects 50 camera streams into one NATS cluster.
- **Web Dashboard:** Monitors can "tune in" to any camera by subscribing to its specific subject.

---
*Part of the 100-Lesson NATS Series.*
