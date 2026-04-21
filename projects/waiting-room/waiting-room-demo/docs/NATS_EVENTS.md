# NATS Event Schema Design

## Overview

NATS JetStream provides durable, at-least-once message delivery for internal events. This document defines the event schema, subjects, and stream configuration for the waiting room system.

---

## Subject Naming Convention

```
{domain}.{entity}.{action}.{version}

Examples:
- waitingroom.position.enqueued.v1
- waitingroom.position.admitted.v1
- waitingroom.session.started.v1
- waitingroom.queue.updated.v1
```

---

## Event Categories

### 1. Position Events

| Subject | Description |
|---------|-------------|
| `waitingroom.position.enqueued.v1` | User joined queue |
| `waitingroom.position.admitted.v1` | User admitted from queue |
| `waitingroom.position.expired.v1` | Position expired (timeout) |
| `waitingroom.position.cancelled.v1` | User cancelled position |
| `waitingroom.position.heartbeat.v1` | Heartbeat received |

### 2. Session Events

| Subject | Description |
|---------|-------------|
| `waitingroom.session.started.v1` | Session created |
| `waitingroom.session.active.v1` | Session activity |
| `waitingroom.session.expired.v1` | Session expired |
| `waitingroom.session.terminated.v1` | Session terminated |

### 3. Queue Events

| Subject | Description |
|---------|-------------|
| `waitingroom.queue.created.v1` | Queue created |
| `waitingroom.queue.updated.v1` | Queue configuration updated |
| `waitingroom.queue.paused.v1` | Queue paused |
| `waitingroom.queue.resumed.v1` | Queue resumed |
| `waitingroom.queue.maintenance.v1` | Queue in maintenance mode |

### 4. System Events

| Subject | Description |
|---------|-------------|
| `waitingroom.system.health.v1` | Health check events |
| `waitingroom.system.error.v1` | Error events |
| `waitingroom.system.metrics.v1` | Metrics snapshots |

---

## Event Schema

### Base Event Structure

All events share a common base structure:

```go
type Event struct {
    // Metadata
    ID        string    `json:"id"`         // UUID
    Version   string    `json:"version"`    // Schema version (e.g., "1.0")
    Type      string    `json:"type"`       // Event type
    Timestamp time.Time `json:"timestamp"`  // Event timestamp (ISO 8601)
    Source    string    `json:"source"`     // Service that produced the event
    
    // Tracing
    TraceID   string    `json:"trace_id,omitempty"`   // Distributed tracing ID
    SpanID    string    `json:"span_id,omitempty"`    // Span ID
    
    // Context
    QueueID   string    `json:"queue_id,omitempty"`   // Queue context
    
    // Payload
    Data      any       `json:"data"`       // Event-specific payload
}
```

### JSON Schema

```json
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "$id": "https://waitingroom.example.com/schemas/event.json",
    "title": "Base Event",
    "type": "object",
    "required": ["id", "version", "type", "timestamp", "source", "data"],
    "properties": {
        "id": {
            "type": "string",
            "format": "uuid"
        },
        "version": {
            "type": "string",
            "pattern": "^\\d+\\.\\d+$"
        },
        "type": {
            "type": "string"
        },
        "timestamp": {
            "type": "string",
            "format": "date-time"
        },
        "source": {
            "type": "string"
        },
        "trace_id": {
            "type": "string"
        },
        "span_id": {
            "type": "string"
        },
        "queue_id": {
            "type": "string"
        },
        "data": {
            "type": "object"
        }
    }
}
```

---

## Event Payloads

### Position Enqueued

```go
type PositionEnqueuedData struct {
    PositionID  string                 `json:"position_id"`
    Priority    int                    `json:"priority"`
    IPAddress   string                 `json:"ip_address,omitempty"`  // Masked
    UserAgent   string                 `json:"user_agent,omitempty"`  // Truncated
    Metadata    map[string]any         `json:"metadata,omitempty"`
    QueueLength int64                  `json:"queue_length"`
}
```

**Example:**
```json
{
    "id": "evt-550e8400-e29b-41d4-a716",
    "version": "1.0",
    "type": "position.enqueued",
    "timestamp": "2024-01-01T12:00:00Z",
    "source": "waitingroom-api",
    "trace_id": "trace-abc123",
    "queue_id": "concert-tickets",
    "data": {
        "position_id": "pos-550e8400-e29b-41d4-a716",
        "priority": 0,
        "ip_address": "192.168.1.***",
        "queue_length": 1523
    }
}
```

### Position Admitted

```go
type PositionAdmittedData struct {
    PositionID  string    `json:"position_id"`
    SessionID   string    `json:"session_id"`
    WaitTime    int64     `json:"wait_time_seconds"`
    QueueLength int64     `json:"queue_length_after"`
}
```

**Example:**
```json
{
    "id": "evt-a1b2c3d4-e5f6-7890",
    "version": "1.0",
    "type": "position.admitted",
    "timestamp": "2024-01-01T12:05:00Z",
    "source": "waitingroom-api",
    "queue_id": "concert-tickets",
    "data": {
        "position_id": "pos-550e8400-e29b-41d4-a716",
        "session_id": "sess-a1b2c3d4-e5f6-7890",
        "wait_time_seconds": 300,
        "queue_length_after": 1522
    }
}
```

### Position Expired

```go
type PositionExpiredData struct {
    PositionID  string    `json:"position_id"`
    Reason      string    `json:"reason"`      // heartbeat_timeout, cancelled, admin_revoked
    WaitTime    int64     `json:"wait_time_seconds"`
    QueueLength int64     `json:"queue_length_after"`
}
```

**Example:**
```json
{
    "id": "evt-expired-123",
    "version": "1.0",
    "type": "position.expired",
    "timestamp": "2024-01-01T12:10:00Z",
    "source": "waitingroom-cleanup",
    "queue_id": "concert-tickets",
    "data": {
        "position_id": "pos-xyz789",
        "reason": "heartbeat_timeout",
        "wait_time_seconds": 180,
        "queue_length_after": 1521
    }
}
```

### Session Started

```go
type SessionStartedData struct {
    SessionID   string    `json:"session_id"`
    PositionID  string    `json:"position_id"`
    IPAddress   string    `json:"ip_address,omitempty"`
    ExpiresAt   time.Time `json:"expires_at"`
}
```

### Session Expired

```go
type SessionExpiredData struct {
    SessionID   string    `json:"session_id"`
    PositionID  string    `json:"position_id"`
    Duration    int64     `json:"duration_seconds"`
    PageViews   int       `json:"page_views"`
    Reason      string    `json:"reason"`
}
```

### Queue Updated

```go
type QueueUpdatedData struct {
    QueueID       string            `json:"queue_id"`
    Changes       map[string]Change `json:"changes"`
    UpdatedBy     string            `json:"updated_by"`
}

type Change struct {
    OldValue any `json:"old_value"`
    NewValue any `json:"new_value"`
}
```

**Example:**
```json
{
    "id": "evt-queue-update-1",
    "version": "1.0",
    "type": "queue.updated",
    "timestamp": "2024-01-01T12:00:00Z",
    "source": "waitingroom-admin",
    "queue_id": "concert-tickets",
    "data": {
        "queue_id": "concert-tickets",
        "changes": {
            "admission_rate": {
                "old_value": 10,
                "new_value": 20
            },
            "max_active": {
                "old_value": 1000,
                "new_value": 2000
            }
        },
        "updated_by": "admin@example.com"
    }
}
```

---

## JetStream Configuration

### Stream Definition

```yaml
# Position Events Stream
stream:
  name: POSITION_EVENTS
  subjects:
    - waitingroom.position.*.v1
  retention: limits
  max_msgs: 1000000
  max_bytes: 1GB
  max_age: 168h  # 7 days
  duplicates: 5m
  replicas: 3
  ack_wait: 30s
  max_deliver: 3

# Session Events Stream
stream:
  name: SESSION_EVENTS
  subjects:
    - waitingroom.session.*.v1
  retention: limits
  max_msgs: 500000
  max_bytes: 512MB
  max_age: 168h
  duplicates: 5m
  replicas: 3

# Queue Events Stream
stream:
  name: QUEUE_EVENTS
  subjects:
    - waitingroom.queue.*.v1
  retention: limits
  max_msgs: 100000
  max_bytes: 100MB
  max_age: 720h  # 30 days
  duplicates: 5m
  replicas: 3

# System Events Stream
stream:
  name: SYSTEM_EVENTS
  subjects:
    - waitingroom.system.*.v1
  retention: limits
  max_msgs: 100000
  max_bytes: 100MB
  max_age: 24h
  duplicates: 1m
  replicas: 3
```

### Consumer Definitions

```yaml
# Analytics Consumer
consumer:
  name: analytics-processor
  stream: POSITION_EVENTS
  durable: true
  deliver_all: true
  ack_policy: explicit
  filter_subject: waitingroom.position.>
  
# Notification Consumer
consumer:
  name: notification-service
  stream: SESSION_EVENTS
  durable: true
  deliver_all: true
  ack_policy: explicit
  filter_subject: waitingroom.session.>
  
# Audit Log Consumer
consumer:
  name: audit-logger
  stream: QUEUE_EVENTS
  durable: true
  deliver_all: true
  ack_policy: explicit
```

---

## Go Implementation

### Event Publisher

```go
package broker

import (
    "context"
    "encoding/json"
    "time"
    
    "github.com/google/uuid"
    "github.com/nats-io/nats.go"
    "github.com/nats-io/nats.go/jetstream"
)

type EventPublisher struct {
    js     jetstream.JetStream
    source string
}

func NewEventPublisher(nc *nats.Conn, source string) (*EventPublisher, error) {
    js, err := jetstream.New(nc)
    if err != nil {
        return nil, err
    }
    return &EventPublisher{js: js, source: source}, nil
}

func (p *EventPublisher) Publish(ctx context.Context, subject string, eventType string, queueID string, data any) error {
    event := Event{
        ID:        uuid.New().String(),
        Version:   "1.0",
        Type:      eventType,
        Timestamp: time.Now().UTC(),
        Source:    p.source,
        QueueID:   queueID,
        Data:      data,
    }
    
    // Extract trace context if available
    if traceID := ctx.Value("trace_id"); traceID != nil {
        event.TraceID = traceID.(string)
    }
    
    payload, err := json.Marshal(event)
    if err != nil {
        return err
    }
    
    _, err = p.js.Publish(ctx, subject, payload)
    return err
}

// Convenience methods
func (p *EventPublisher) PublishPositionEnqueued(ctx context.Context, queueID string, data *PositionEnqueuedData) error {
    return p.Publish(ctx, 
        "waitingroom.position.enqueued.v1",
        "position.enqueued",
        queueID,
        data,
    )
}

func (p *EventPublisher) PublishPositionAdmitted(ctx context.Context, queueID string, data *PositionAdmittedData) error {
    return p.Publish(ctx,
        "waitingroom.position.admitted.v1",
        "position.admitted",
        queueID,
        data,
    )
}

func (p *EventPublisher) PublishPositionExpired(ctx context.Context, queueID string, data *PositionExpiredData) error {
    return p.Publish(ctx,
        "waitingroom.position.expired.v1",
        "position.expired",
        queueID,
        data,
    )
}
```

### Event Subscriber

```go
package broker

import (
    "context"
    "encoding/json"
    "log"
    
    "github.com/nats-io/nats.go/jetstream"
)

type EventHandler func(ctx context.Context, event *Event) error

type EventSubscriber struct {
    js       jetstream.JetStream
    handlers map[string]EventHandler
}

func NewEventSubscriber(nc *nats.Conn) (*EventSubscriber, error) {
    js, err := jetstream.New(nc)
    if err != nil {
        return nil, err
    }
    return &EventSubscriber{
        js:       js,
        handlers: make(map[string]EventHandler),
    }, nil
}

func (s *EventSubscriber) RegisterHandler(eventType string, handler EventHandler) {
    s.handlers[eventType] = handler
}

func (s *EventSubscriber) Subscribe(ctx context.Context, streamName, consumerName string) error {
    stream, err := s.js.Stream(ctx, streamName)
    if err != nil {
        return err
    }
    
    consumer, err := stream.Consumer(ctx, consumerName)
    if err != nil {
        return err
    }
    
    _, err = consumer.Consume(func(msg jetstream.Msg) {
        var event Event
        if err := json.Unmarshal(msg.Data(), &event); err != nil {
            log.Printf("failed to unmarshal event: %v", err)
            msg.Nak()
            return
        }
        
        handler, ok := s.handlers[event.Type]
        if !ok {
            log.Printf("no handler for event type: %s", event.Type)
            msg.Ack()
            return
        }
        
        if err := handler(ctx, &event); err != nil {
            log.Printf("handler error for event %s: %v", event.ID, err)
            msg.Nak()
            return
        }
        
        msg.Ack()
    })
    
    return err
}
```

---

## Event Versioning

### Version Strategy

1. **Major Version (v1, v2)**: Breaking changes, new subject
2. **Minor Version (1.0, 1.1)**: Non-breaking additions, same subject

### Backward Compatibility

```go
// v1.0 handler
func handlePositionEnqueuedV1(ctx context.Context, event *Event) error {
    var data PositionEnqueuedData
    // ... handle v1.0 format
}

// v1.1 handler (backward compatible)
func handlePositionEnqueuedV11(ctx context.Context, event *Event) error {
    var data PositionEnqueuedDataV11
    // ... handle v1.1 format with new fields
    // ... fall back to v1.0 logic for missing fields
}
```

### Schema Registry

```go
type SchemaRegistry struct {
    schemas map[string]string
}

func (r *SchemaRegistry) Validate(eventType string, version string, data []byte) error {
    schemaKey := fmt.Sprintf("%s.%s", eventType, version)
    schema, ok := r.schemas[schemaKey]
    if !ok {
        return fmt.Errorf("unknown schema: %s", schemaKey)
    }
    
    // Validate against JSON schema
    // ...
    return nil
}
```

---

## Dead Letter Queue

### Configuration

```yaml
stream:
  name: DEAD_LETTER_QUEUE
  subjects:
    - waitingroom.dlq.>
  retention: limits
  max_msgs: 10000
  max_age: 168h  # 7 days
```

### Implementation

```go
func (s *EventSubscriber) handleWithDLQ(ctx context.Context, msg jetstream.Msg, handler EventHandler) {
    var event Event
    if err := json.Unmarshal(msg.Data(), &event); err != nil {
        s.sendToDLQ(ctx, msg, "unmarshal_error", err)
        msg.Ack()
        return
    }
    
    // Check delivery count
    info, _ := msg.Info()
    if info.Delivered > 3 {
        s.sendToDLQ(ctx, msg, "max_retries_exceeded", nil)
        msg.Ack()
        return
    }
    
    if err := handler(ctx, &event); err != nil {
        log.Printf("handler error: %v", err)
        msg.Nak()
        return
    }
    
    msg.Ack()
}

func (s *EventSubscriber) sendToDLQ(ctx context.Context, msg jetstream.Msg, reason string, originalErr error) {
    dlqMsg := DLQMessage{
        OriginalSubject: msg.Subject(),
        OriginalData:    msg.Data(),
        Reason:          reason,
        Error:           "",
        Timestamp:       time.Now().UTC(),
    }
    if originalErr != nil {
        dlqMsg.Error = originalErr.Error()
    }
    
    payload, _ := json.Marshal(dlqMsg)
    s.js.Publish(ctx, "waitingroom.dlq.event", payload)
}

type DLQMessage struct {
    OriginalSubject string    `json:"original_subject"`
    OriginalData    []byte    `json:"original_data"`
    Reason          string    `json:"reason"`
    Error           string    `json:"error"`
    Timestamp       time.Time `json:"timestamp"`
}
```

---

## Monitoring

### Metrics

```go
var (
    EventsPublished = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "waitingroom_events_published_total",
        Help: "Total events published",
    }, []string{"event_type", "queue_id"})
    
    EventsProcessed = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "waitingroom_events_processed_total",
        Help: "Total events processed",
    }, []string{"event_type", "status"})
    
    EventLatency = promauto.NewHistogramVec(prometheus.HistogramOpts{
        Name: "waitingroom_event_latency_seconds",
        Help: "Event processing latency",
        Buckets: []float64{.001, .005, .01, .025, .05, .1, .25, .5, 1},
    }, []string{"event_type"})
)
```

### Health Check

```go
func (p *EventPublisher) HealthCheck(ctx context.Context) error {
    // Check NATS connection
    if !p.nc.IsConnected() {
        return fmt.Errorf("NATS not connected")
    }
    
    // Check JetStream availability
    _, err := p.js.AccountInfo(ctx)
    if err != nil {
        return fmt.Errorf("JetStream unavailable: %w", err)
    }
    
    return nil
}
```
