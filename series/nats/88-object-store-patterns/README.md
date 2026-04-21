# 88 — Object Store Patterns

> **Type:** Tutorial  
> **Phase:** Advanced & Real-World

## What you're building

Learn to store and retrieve large files (binaries, logs, assets) using **NATS Object Store**, which splits large objects into manageable chunks inside JetStream.

## 1. Why Object Store?

Standard NATS messages have a `max_payload` limit (usually 1MB). Object store allows you to store files of virtually any size by:
- Splitting the file into **chunks** (default 128KB).
- Storing chunks in a dedicated NATS stream.
- Providing high-level API for `Put` and `Get`.

## 2. Creating an Object Bucket

```go
js, _ := nc.JetStream()
os, _ := js.CreateObjectStore(&nats.ObjectStoreConfig{
    Bucket: "assets",
})
```

## 3. Storing a File

```go
file, _ := os.Open("image.png")
defer file.Close()

// Store metadata with the object
_, err := os.Put(&nats.ObjectMeta{Name: "logos/primary.png"}, file)
```

## 4. Retrieving a File

```go
// Get returns an ObjectResult which implements io.ReadCloser
result, _ := os.Get("logos/primary.png")
defer result.Close()

// Stream directly to a local file or HTTP response
io.Copy(localFile, result)
```

## 5. Watching for File Changes

```go
watcher, _ := os.Watch()
for info := range watcher.Updates() {
    fmt.Printf("File %s: Size %d bytes, Modified %v\n", 
        info.Name, info.Size, info.ModTime)
}
```

## 6. Advanced Pattern: Large-Scale Asset Distribution
- **Hub:** Publishes large firmware updates to the `FIRMWARE` Object Store.
- **Edge Nodes:** Receive an event "Firmware V2.0 ready", then pull the binary from the local object store mirror.

---
*Part of the 100-Lesson NATS Series.*
