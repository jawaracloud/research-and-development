# 87 — Advanced KV Patterns

> **Type:** Tutorial  
> **Phase:** Advanced & Real-World

## What you're building

Go beyond simple key-value lookups. Implement advanced patterns like **Watches**, **Optimistic Locking**, and **History** using NATS Key-Value.

## 1. Key Discovery & Watching

Instead of polling for updates, watch a bucket (or a specific key) for real-time changes.

```go
kv, _ := js.KeyValue("config")

// Watch all keys in the bucket
watcher, _ := kv.WatchAll()
defer watcher.Stop()

for entry := range watcher.Updates() {
    if entry == nil { continue } // initial sync done
    fmt.Printf("Key %s changed to %s\n", entry.Key(), entry.Value())
}
```

## 2. Optimistic Locking (CAS)

Prevent "Lost Updates" by only updating a key if its version hasn't changed since you last read it. (Compare-And-Swap).

```go
entry, _ := kv.Get("counter")
currentValue := string(entry.Value())

// Business logic...
newValue := someCalc(currentValue)

// Try to update specifically for the version we read
_, err := kv.Update("counter", []byte(newValue), entry.Revision())
if err != nil {
    // Version mismatch! Retry the read-process-update cycle.
}
```

## 3. History Management

NATS KV can store a history of changes for every key.

```go
// Add bucket with history
js.CreateKeyValue(&nats.KeyValueConfig{
    Bucket:  "features",
    History: 5,  // Keep last 5 versions of every key
})

// Retrieve history for a key
history, _ := kv.History("theme")
for _, entry := range history {
    fmt.Printf("Ver %d: %s\n", entry.Revision(), entry.Value())
}
```

## 4. TTL per Bucket

Use TTL to automatically expire keys (e.g., for temporary session tokens).

```go
js.CreateKeyValue(&nats.KeyValueConfig{
    Bucket: "sessions",
    TTL:    time.Hour * 1,
})
```

## 5. Use Case: Feature Flag System
- **Keys:** `feature.new-checkout`, `feature.dark-mode`.
- **Clients:** Watch the keys and update UI instantly when a flag is toggled in the admin dashboard.

---
*Part of the 100-Lesson NATS Series.*
