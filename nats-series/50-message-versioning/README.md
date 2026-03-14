# 50 — Message Versioning

> **Type:** How-To  
> **Phase:** Patterns & Architecture

## Overview

As systems evolve, message schemas change. Message versioning allows producers and consumers to evolve independently without breaking each other.

## Versioning Strategies

### Strategy 1: Version in Subject

```
orders.v1.created    → legacy schema
orders.v2.created    → new schema
```

Consumers subscribe to what they support:
```go
nc.Subscribe("orders.v2.created", modernHandler)
nc.Subscribe("orders.v1.created", legacyHandler)
```

### Strategy 2: Version in Header

```go
msg.Header.Set("Schema-Version", "2")
msg.Header.Set("Content-Type", "application/json")
```

Consumer reads header to select deserialiser:
```go
nc.Subscribe("orders.created", func(msg *nats.Msg) {
    version := msg.Header.Get("Schema-Version")
    switch version {
    case "2":
        var event OrderCreatedV2
        json.Unmarshal(msg.Data, &event)
        processV2(event)
    default:
        var event OrderCreatedV1
        json.Unmarshal(msg.Data, &event)
        processV1(event)
    }
})
```

### Strategy 3: Envelope Pattern (recommended)

Wrap all messages in a versioned envelope:

```go
type Envelope struct {
    SchemaVersion string          `json:"schemaVersion"`
    EventType     string          `json:"eventType"`
    EventID       string          `json:"eventId"`
    Timestamp     time.Time       `json:"ts"`
    Data          json.RawMessage `json:"data"`
}

// Publisher
func publishEvent(js nats.JetStreamContext, subject, eventType string, data interface{}) {
    payload, _ := json.Marshal(data)
    env := Envelope{
        SchemaVersion: "2",
        EventType:     eventType,
        EventID:       uuid.New().String(),
        Timestamp:     time.Now().UTC(),
        Data:          payload,
    }
    body, _ := json.Marshal(env)
    js.Publish(subject, body)
}

// Consumer
func handleEnvelope(msg *nats.Msg) {
    var env Envelope
    json.Unmarshal(msg.Data, &env)

    switch env.SchemaVersion + "/" + env.EventType {
    case "2/OrderCreated":
        var ev OrderCreatedV2
        json.Unmarshal(env.Data, &ev)
        processV2(ev)
    case "1/OrderCreated":
        var ev OrderCreatedV1
        json.Unmarshal(env.Data, &ev)
        processV1(ev)
    }
}
```

## Schema Evolution Rules

**Safe** (backward compatible):
- ✅ Add a new optional field with a default
- ✅ Rename field in a new schema version

**Breaking** (requires new version):
- ❌ Remove a required field
- ❌ Change field type (string → int)
- ❌ Change semantic meaning of a field

## Migration Pattern

```
1. Deploy v2 producer alongside v1 (dual publish to v1 and v2 subjects)
2. Update all consumers to support v2
3. Remove v1 publishing after all consumers are on v2
4. Remove v1 consumer code
```

---
*Part of the 100-Lesson NATS Series.*
