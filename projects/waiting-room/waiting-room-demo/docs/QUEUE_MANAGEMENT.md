# Queue Management System Design

## Overview

The queue management system is the core of the waiting room. It handles user enrollment, position tracking, admission control, and queue state transitions.

---

## FIFO Queue Implementation

### Data Structure

Using Redis LIST for the main queue:

```
Key: queue:{queue_id}:waiting
Type: LIST
Values: position_id (UUID)

Operations:
- LPUSH: Add to front (for priority)
- RPUSH: Add to back (normal)
- RPOP: Remove from front (admit)
- LLEN: Get queue length
- LINDEX: Get position at index
```

### Position Tracking

Using Redis Sorted Set (ZSET) for efficient position queries:

```
Key: queue:{queue_id}:positions
Type: ZSET (Sorted Set)
Member: position_id
Score: timestamp (microseconds since epoch)

Operations:
- ZADD: Add position with timestamp score
- ZRANK: Get position rank (0-indexed)
- ZREM: Remove position
- ZCARD: Get total count
- ZRANGE: Get range of positions
```

### Position Metadata

Using Redis HASH for position details:

```
Key: position:{position_id}
Type: HASH
Fields:
  - queue_id: string
  - session_id: string
  - status: string (waiting|active|expired|completed)
  - priority: int
  - enqueued_at: timestamp
  - last_heartbeat: timestamp
  - ip_address: string
  - user_agent: string
  - metadata: JSON string
```

---

## Priority Handling

### Priority Levels

| Level | Name | Behavior |
|-------|------|----------|
| 0 | Normal | Standard FIFO queue |
| 1 | Elevated | Skip ahead 10% of queue |
| 2 | VIP | Skip ahead 50% of queue |
| 3 | Premium | Immediate admission (if capacity) |

### Implementation Strategy

**Two-Queue Approach:**

```
queue:{queue_id}:priority:3  -> Premium (immediate)
queue:{queue_id}:priority:2  -> VIP
queue:{queue_id}:priority:1  -> Elevated
queue:{queue_id}:priority:0  -> Normal
```

**Admission Order:**
1. Check priority:3 queue first
2. Then priority:2, priority:1, priority:0
3. Within each queue, FIFO order

**Lua Script for Atomic Priority Enqueue:**

```lua
-- KEYS[1] = queue:{queue_id}:priority:{level}
-- KEYS[2] = queue:{queue_id}:positions
-- KEYS[3] = position:{position_id}
-- ARGV[1] = position_id
-- ARGV[2] = timestamp
-- ARGV[3] = metadata JSON

-- Add to priority queue
redis.call('LPUSH', KEYS[1], ARGV[1])

-- Add to sorted set for position tracking
redis.call('ZADD', KEYS[2], ARGV[2], ARGV[1])

-- Store metadata
redis.call('HSET', KEYS[3], 
    'status', 'waiting',
    'enqueued_at', ARGV[2],
    'last_heartbeat', ARGV[2],
    'metadata', ARGV[3]
)

-- Set TTL on position (30 minutes default)
redis.call('EXPIRE', KEYS[3], 1800)

return ARGV[1]
```

---

## Queue State Transitions

### State Diagram

```
         +--------+
         |  NULL  | (not in queue)
         +---+----+
             |
             | enqueue()
             v
    +--------+--------+
    |     WAITING     |
    +--------+--------+
             |
    +--------+--------+
    |                 |
    v                 v
+---+----+      +-----+------+
| EXPIRED|      |  ADMITTED  |
+--------+      +-----+------+
                      |
                      | session_start()
                      v
                +-----+------+
                |   ACTIVE   |
                +-----+------+
                      |
              +-------+-------+
              |               |
              v               v
        +-----+------+  +-----+-------+
        |  EXPIRED   |  |  COMPLETED  |
        +------------+  +-------------+
```

### Transition Rules

| Current State | Event | Next State | Side Effects |
|---------------|-------|------------|--------------|
| NULL | enqueue | WAITING | Create position, start heartbeat timer |
| WAITING | admit | ADMITTED | Remove from queue, generate token |
| WAITING | timeout | EXPIRED | Remove from queue, emit event |
| WAITING | cancel | EXPIRED | Remove from queue, emit event |
| ADMITTED | session_start | ACTIVE | Create session record |
| ADMITTED | timeout | EXPIRED | Invalidate token |
| ACTIVE | timeout | EXPIRED | Terminate session |
| ACTIVE | complete | COMPLETED | Clean up session |
| ACTIVE | terminate | EXPIRED | Force session end |

---

## Admission Control

### Token Bucket Algorithm

Control the rate of users admitted to the protected resource:

```
Bucket Configuration:
- Capacity: max_active_users
- Refill Rate: queue_rate (users/second)
- Initial Tokens: max_active_users

Algorithm:
1. On admission request:
   a. Check if tokens available
   b. If yes: consume token, admit user
   c. If no: user waits in queue

2. Token refill:
   a. Background goroutine adds tokens at queue_rate
   b. Never exceeds capacity
```

### Implementation

```go
type AdmissionController struct {
    tokens      int64
    capacity    int64
    refillRate  int64  // tokens per second
    lastRefill  time.Time
    mu          sync.Mutex
}

func (ac *AdmissionController) TryAdmit() bool {
    ac.mu.Lock()
    defer ac.mu.Unlock()
    
    // Refill tokens based on elapsed time
    now := time.Now()
    elapsed := now.Sub(ac.lastRefill).Seconds()
    refill := int64(elapsed * float64(ac.refillRate))
    
    ac.tokens = min(ac.tokens + refill, ac.capacity)
    ac.lastRefill = now
    
    if ac.tokens > 0 {
        ac.tokens--
        return true
    }
    return false
}
```

### Distributed Admission Control

For multi-instance deployment, use Redis-based token bucket:

```lua
-- KEYS[1] = admission:{queue_id}:tokens
-- ARGV[1] = capacity
-- ARGV[2] = refill_rate
-- ARGV[3] = current_timestamp

local tokens = redis.call('GET', KEYS[1])
if tokens == false then
    tokens = ARGV[1]
end

-- Calculate refill
local last_update = redis.call('GET', KEYS[1] .. ':last_update')
if last_update == false then
    last_update = ARGV[3]
end

local elapsed = ARGV[3] - last_update
local refill = math.floor(elapsed * ARGV[2])
tokens = math.min(tokens + refill, ARGV[1])

if tokens > 0 then
    redis.call('DECR', KEYS[1])
    redis.call('SET', KEYS[1] .. ':last_update', ARGV[3])
    return 1
end

return 0
```

---

## Queue Operations

### Enqueue

```go
func (q *QueueService) Enqueue(ctx context.Context, req EnqueueRequest) (*Position, error) {
    // 1. Check if queue is at capacity
    if q.IsAtCapacity(ctx, req.QueueID) {
        return nil, ErrQueueFull
    }
    
    // 2. Check for duplicate (same IP/session)
    if existing := q.FindByIP(ctx, req.QueueID, req.IPAddress); existing != nil {
        return existing, nil // Return existing position
    }
    
    // 3. Create position
    position := &Position{
        ID:          uuid.New().String(),
        QueueID:     req.QueueID,
        Priority:    req.Priority,
        Status:      StatusWaiting,
        EnqueuedAt:  time.Now(),
        IPAddress:   req.IPAddress,
        UserAgent:   req.UserAgent,
    }
    
    // 4. Atomic enqueue via Lua script
    err := q.store.EnqueuePosition(ctx, position)
    if err != nil {
        return nil, err
    }
    
    // 5. Emit event
    q.broker.Publish(ctx, Event{
        Type:      EventTypeEnqueued,
        QueueID:   req.QueueID,
        PositionID: position.ID,
        Timestamp: time.Now(),
    })
    
    return position, nil
}
```

### Dequeue (Admit)

```go
func (q *QueueService) AdmitNext(ctx context.Context, queueID string) (*Position, error) {
    // 1. Check admission controller
    if !q.admission.TryAdmit() {
        return nil, ErrNoCapacity
    }
    
    // 2. Get next position (priority-aware)
    position, err := q.store.DequeuePosition(ctx, queueID)
    if err != nil {
        q.admission.ReturnToken() // Return token if no one to admit
        return nil, err
    }
    
    // 3. Update position status
    position.Status = StatusAdmitted
    position.AdmittedAt = time.Now()
    q.store.UpdatePosition(ctx, position)
    
    // 4. Generate session token
    token, err := q.tokenService.Generate(ctx, position)
    if err != nil {
        return nil, err
    }
    position.Token = token
    
    // 5. Emit event
    q.broker.Publish(ctx, Event{
        Type:       EventTypeAdmitted,
        QueueID:    queueID,
        PositionID: position.ID,
        Timestamp:  time.Now(),
    })
    
    return position, nil
}
```

### Get Position

```go
func (q *QueueService) GetPosition(ctx context.Context, positionID string) (*PositionInfo, error) {
    // 1. Get position metadata
    position, err := q.store.GetPosition(ctx, positionID)
    if err != nil {
        return nil, err
    }
    
    // 2. Calculate current rank
    rank, err := q.store.GetPositionRank(ctx, position.QueueID, positionID)
    if err != nil {
        rank = -1 // Not in queue
    }
    
    // 3. Calculate estimated wait time
    queueLength, _ := q.store.GetQueueLength(ctx, position.QueueID)
    estimatedWait := q.estimateWaitTime(rank, queueLength)
    
    return &PositionInfo{
        Position:      position,
        QueuePosition: rank + 1, // Convert 0-indexed to 1-indexed
        QueueLength:   queueLength,
        EstimatedWait: estimatedWait,
    }, nil
}

func (q *QueueService) estimateWaitTime(rank int64, queueLength int64) time.Duration {
    if rank < 0 {
        return 0
    }
    
    // Estimate based on admission rate
    // Wait = position / rate
    rate := q.config.AdmissionRate // users per second
    if rate <= 0 {
        rate = 1
    }
    
    seconds := float64(rank) / float64(rate)
    return time.Duration(seconds * float64(time.Second))
}
```

---

## Queue Maintenance

### Cleanup Worker

Removes expired positions and stale sessions:

```go
func (q *QueueService) RunCleanup(ctx context.Context, interval time.Duration) {
    ticker := time.NewTicker(interval)
    defer ticker.Stop()
    
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            q.cleanupExpired(ctx)
        }
    }
}

func (q *QueueService) cleanupExpired(ctx context.Context) {
    // Find positions with last_heartbeat > timeout
    expired, err := q.store.FindExpiredPositions(ctx, q.config.HeartbeatTimeout)
    if err != nil {
        log.Printf("cleanup error: %v", err)
        return
    }
    
    for _, pos := range expired {
        // Remove from queue
        q.store.RemovePosition(ctx, pos.QueueID, pos.ID)
        
        // Update status
        pos.Status = StatusExpired
        q.store.UpdatePosition(ctx, pos)
        
        // Emit event
        q.broker.Publish(ctx, Event{
            Type:       EventTypeExpired,
            QueueID:    pos.QueueID,
            PositionID: pos.ID,
            Reason:     "heartbeat_timeout",
            Timestamp:  time.Now(),
        })
    }
}
```

### Queue Statistics

```go
type QueueStats struct {
    QueueID           string
    TotalWaiting      int64
    TotalActive       int64
    TotalExpired      int64
    AvgWaitTime       time.Duration
    AdmissionRate     float64 // users/second
    LastAdmissionTime time.Time
}

func (q *QueueService) GetStats(ctx context.Context, queueID string) (*QueueStats, error) {
    stats := &QueueStats{QueueID: queueID}
    
    // Get counts from Redis
    stats.TotalWaiting = q.store.GetQueueLength(ctx, queueID)
    stats.TotalActive = q.store.GetActiveCount(ctx, queueID)
    stats.TotalExpired = q.store.GetExpiredCount(ctx, queueID)
    
    // Calculate averages from recent history
    stats.AvgWaitTime = q.calculateAvgWaitTime(ctx, queueID)
    stats.AdmissionRate = q.calculateAdmissionRate(ctx, queueID)
    
    return stats, nil
}
```
