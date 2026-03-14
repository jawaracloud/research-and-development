# 98 — Extending NATS with Custom Bridges

> **Type:** Tutorial  
> **Phase:** Advanced & Real-World

## What you're building

Learn how to write a custom bridge in Go to connect NATS to an external system that isn't supported natively (e.g., Slack, Discord, custom legacy SQL).

## 1. The Bridge Pattern

A bridge is a small application that:
1. Subscribes to NATS.
2. Translates the message.
3. Performs an external action.

## 2. Example: NATS to Slack Bridge

```go
func main() {
    nc, _ := nats.Connect(nats.DefaultURL)
    
    nc.Subscribe("alerts.critical", func(msg *nats.Msg) {
        // Translate NATS msg to Slack JSON
        slackPayload := map[string]string{
            "text": fmt.Sprintf("🚨 Critical Alert: %s", string(msg.Data)),
        }
        
        // External call
        http.Post(slackWebhookURL, "application/json", mustJSON(slackPayload))
        
        // Ack if using JetStream
        // msg.Ack()
    })
    
    select {}
}
```

## 3. Bidirectional Bridges (Webhooks)

A bridge can also take an external webhook and publish it *into* NATS.

```go
http.HandleFunc("/github-webhook", func(w http.ResponseWriter, r *http.Request) {
    data, _ := io.ReadAll(r.Body)
    nc.Publish("github.events.push", data)
    w.WriteHeader(200)
})
```

## 4. Resiliency in Bridges
- **Use JetStream:** If the bridge crashes or the external API is down, JetStream will store the messages until the bridge recovers.
- **Retries:** Use exponential backoff when calling external APIs to avoid getting rate-limited.

## 5. Deployment
Bridges should be deployed as small, stateless containers (e.g., in a Kubernetes Deployment) and can be scaled using queue groups.

---
*Part of the 100-Lesson NATS Series.*
