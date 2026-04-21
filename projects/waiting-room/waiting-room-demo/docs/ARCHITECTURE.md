# Waiting Room Demo - Architecture Design

## Core Concepts

### 1. Queue Position

A **Queue Position** represents a user's place in the waiting line. It is the fundamental unit of the waiting room system.

```
QueuePosition {
    ID           string    // Unique identifier (UUID)
    QueueID      string    // Which queue this position belongs to
    SessionID    string    // Linked session for this user
    Position     int64     // Current position in queue (1 = front)
    Priority     int       // Priority level (0 = normal, higher = more important)
    Status       string    // waiting | active | expired | completed
    EnqueuedAt   time.Time // When user joined the queue
    ExpiresAt    time.Time // When this position expires
    Metadata     map[string]string // Optional user metadata
}
```

**Key Properties:**
- **Immutable ID**: Once assigned, the position ID never changes
- **Dynamic Position**: The position number updates as users ahead leave
- **TTL-based Expiration**: Positions expire if not refreshed via heartbeat
- **Priority Support**: VIP users can jump ahead in queue

---

### 2. Virtual Waiting Room

A **Virtual Waiting Room** is a managed queue that controls access to a protected resource (e.g., ticket sales, product launch).

```
WaitingRoom {
    ID                    string    // Unique room identifier
    Name                  string    // Human-readable name
    TargetURL             string    // Where users go after passing queue
    MaxActiveUsers        int       // Concurrent users allowed through
    MaxQueueSize          int       // Maximum users in queue (0 = unlimited)
    QueueRate             int       // Users per second to let through
    SessionTimeout        duration  // How long active sessions last
    HeartbeatInterval     duration  // Expected client heartbeat frequency
    HeartbeatTimeout      duration  // Time without heartbeat before removal
    Status                string    // active | paused | maintenance
    CreatedAt             time.Time
    UpdatedAt             time.Time
}
```

**States:**
| State | Behavior |
|-------|----------|
| `active` | Normal operation, users flow through |
| `paused` | No new admissions, existing users maintain position |
| `maintenance` | All users redirected to maintenance page |

---

### 3. Active Session

An **Active Session** represents a user who has passed through the waiting room and is currently accessing the protected resource.

```
Session {
    ID           string    // Unique session identifier
    QueueID      string    // Which queue this came from
    PositionID   string    // Original queue position
    UserID       string    // Optional: authenticated user ID
    IPAddress    string    // Client IP for abuse detection
    UserAgent    string    // Client user agent
    Token        string    // Access token (JWT)
    StartedAt    time.Time // When session began
    ExpiresAt    time.Time // When session expires
    LastSeen     time.Time // Last heartbeat/activity
    PageViews    int       // Number of page views in session
    Status       string    // active | expired | terminated
}
```

**Session Lifecycle:**
```
[Waiting] --> [Active] --> [Expired/Terminated]
     |            |
     v            v
  (removed)   (heartbeat refresh)
```

---

## State Machine

### User Journey States

```
                    +-------------+
                    |   ARRIVAL   |
                    +------+------+
                           |
                           v
                    +------+------+
               +--->|   WAITING   |<---+
               |    +------+------+    |
               |           |          |
          (timeout)        |     (rejoin)
               |           v          |
               |    +------+------+    |
               |    |  ADMITTED   |    |
               |    +------+------+    |
               |           |          |
               |           v          |
               |    +------+------+    |
               +----|   EXPIRED   |----+
                    +-------------+
                           |
                           v
                    +------+------+
                    |  COMPLETED  |
                    +-------------+
```

### State Transitions

| From | To | Trigger | Action |
|------|-----|---------|--------|
| ARRIVAL | WAITING | Enqueue request | Create position, start heartbeat timer |
| WAITING | ADMITTED | Position reaches front | Generate session token, redirect |
| WAITING | EXPIRED | Heartbeat timeout | Remove from queue, notify |
| ADMITTED | ACTIVE | First page view | Start session timer |
| ACTIVE | EXPIRED | Session timeout | Terminate session |
| ACTIVE | COMPLETED | User finishes | Clean up session |
| EXPIRED | WAITING | User rejoins | Create new position (may lose place) |

---

## Key Design Decisions

### 1. Fair Queue Ordering

**Problem**: How to ensure fair ordering when thousands of users join simultaneously?

**Solution**: Use Redis LIST with atomic LPUSH for enqueue and RPOP for dequeue. Each operation is O(1) and atomic, ensuring no race conditions.

```
User joins -> LPUSH queue:waiting <position_id>
Admit user -> RPOP queue:waiting -> get position_id
```

### 2. Position Tracking

**Problem**: Users want to know "how long until I get in?"

**Solution**: 
- Store position metadata in Redis HASH for O(1) lookup
- Use Redis Sorted Set (ZSET) with timestamp as score for efficient position calculation
- Calculate estimated wait time based on queue rate

```
ZSCORE queue:positions <position_id> -> get rank
ZCARD queue:positions -> total in queue
```

### 3. Session Affinity

**Problem**: User refreshes page - do they lose their place?

**Solution**: 
- Issue signed JWT token on enqueue
- Token contains: position_id, queue_id, issued_at, signature
- On reconnect, validate token and restore position
- Position is maintained server-side in Redis with TTL

### 4. Heartbeat Mechanism

**Problem**: Users close browser without leaving queue - position stays occupied.

**Solution**:
- Client must send heartbeat every N seconds
- Server updates "last_seen" timestamp in Redis
- Background worker removes stale positions (last_seen > timeout)
- Grace period for network issues (2-3 missed heartbeats)

---

## Scalability Considerations

### Horizontal Scaling

```
                    +------------------+
                    |   Load Balancer  |
                    +--------+---------+
                             |
         +-------------------+-------------------+
         |                   |                   |
    +----v----+        +----v----+        +----v----+
    | Server 1|        | Server 2|        | Server 3|
    +----+----+        +----+----+        +----+----+
         |                   |                   |
         +-------------------+-------------------+
                             |
                    +--------v---------+
                    |   DragonFlyDB    |
                    |  (Shared State)  |
                    +--------+---------+
                             |
                    +--------v---------+
                    |      NATS        |
                    |   (Event Bus)    |
                    +------------------+
```

### Key Scaling Points

| Component | Scaling Strategy |
|-----------|-----------------|
| API Servers | Stateless, scale horizontally |
| DragonFlyDB | Cluster mode, sharding by queue_id |
| NATS | Cluster mode, partitioned streams |
| Heartbeat Worker | Multiple workers with distributed lock |

---

## Security Model

### Token Security

1. **JWT Signing**: All tokens signed with RS256 (RSA + SHA256)
2. **Short Expiry**: Tokens expire in 5 minutes, refreshed on heartbeat
3. **Claims**: Minimal claims - only position_id, queue_id, iat, exp
4. **No Sensitive Data**: Never include user PII in tokens

### Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/enqueue` | 10 | per minute per IP |
| `/status` | 60 | per minute per token |
| `/heartbeat` | 30 | per minute per token |
| `/session/*` | 100 | per minute per token |

### Abuse Prevention

1. **IP-based throttling**: Prevent same IP from multiple queue positions
2. **Browser fingerprinting**: Detect automated bots
3. **Captcha integration**: Challenge suspicious behavior
4. **Token binding**: Bind token to IP + User-Agent

---

## Failure Modes

### DragonFlyDB Failure

```
Detection: Health check fails
Behavior: 
  - Stop new enrollments
  - Return 503 Service Unavailable
  - Existing sessions continue (cached token)
Recovery: Rebuild state from NATS event log
```

### NATS Failure

```
Detection: Connection timeout
Behavior:
  - Continue operations (NATS is non-blocking)
  - Buffer events locally
  - Retry connection with backoff
Recovery: Replay buffered events
```

### Server Failure

```
Detection: Load balancer health check
Behavior:
  - Load balancer removes from pool
  - Sessions continue (state in DragonFlyDB)
  - Heartbeats resume on new server
Recovery: New server instance spawned
```
