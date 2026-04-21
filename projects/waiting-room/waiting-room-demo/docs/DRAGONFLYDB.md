# DragonFlyDB Data Structures Design

## Overview

DragonFlyDB is a Redis-compatible in-memory data store that provides high performance for our waiting room system. This document defines the data structures, key naming conventions, and TTL policies.

---

## Key Naming Convention

```
{namespace}:{resource}:{identifier}:{sub_resource}

Examples:
- queue:concert-tickets:waiting          # List of waiting positions
- position:550e8400-e29b-41d4-a716       # Position metadata
- session:a1b2c3d4-e5f6-7890             # Session data
- heartbeat:active                        # Sorted set of active heartbeats
- ratelimit:192.168.1.1:enqueue          # Rate limit counter
```

---

## Data Structures

### 1. Queue Metadata

**Key:** `queue:{queue_id}:meta`
**Type:** HASH
**TTL:** None (persistent)

```
Fields:
  name              string    "Concert Ticket Sale"
  target_url        string    "https://example.com/checkout"
  max_active        int       "1000"
  max_queue_size    int       "50000"
  admission_rate    int       "10"        # users per second
  status            string    "active"    # active|paused|maintenance
  created_at        int       "1704067200"
  updated_at        int       "1704067200"
```

**Commands:**
```redis
HSET queue:concert-tickets:meta name "Concert Ticket Sale" target_url "https://example.com/checkout" ...
HGET queue:concert-tickets:meta status
HGETALL queue:concert-tickets:meta
```

---

### 2. Queue Lists (Priority-Based)

**Key:** `queue:{queue_id}:waiting:{priority}`
**Type:** LIST
**TTL:** None (positions have individual TTLs)

```
Priority 0 (Normal):   queue:concert-tickets:waiting:0
Priority 1 (Elevated): queue:concert-tickets:waiting:1
Priority 2 (VIP):      queue:concert-tickets:waiting:2
Priority 3 (Premium):  queue:concert-tickets:waiting:3

Values: position_id (UUID)
```

**Commands:**
```redis
# Enqueue (add to back)
RPUSH queue:concert-tickets:waiting:0 "550e8400-e29b-41d4-a716"

# Priority enqueue (add to front)
LPUSH queue:concert-tickets:waiting:2 "550e8400-e29b-41d4-a716"

# Dequeue (remove from front)
LPOP queue:concert-tickets:waiting:0

# Get queue length
LLEN queue:concert-tickets:waiting:0

# Peek at front
LINDEX queue:concert-tickets:waiting:0 0
```

---

### 3. Position Tracking (Sorted Set)

**Key:** `queue:{queue_id}:positions`
**Type:** ZSET (Sorted Set)
**TTL:** None

```
Member: position_id
Score:  timestamp (microseconds since epoch)

Used for:
- Efficient position calculation (ZRANK)
- Range queries (ZRANGE)
- Total count (ZCARD)
```

**Commands:**
```redis
# Add position with timestamp score
ZADD queue:concert-tickets:positions 1704067200000000 "550e8400-e29b-41d4-a716"

# Get position rank (0-indexed)
ZRANK queue:concert-tickets:positions "550e8400-e29b-41d4-a716"

# Get total in queue
ZCARD queue:concert-tickets:positions

# Remove position
ZREM queue:concert-tickets:positions "550e8400-e29b-41d4-a716"

# Get range (first 10 positions)
ZRANGE queue:concert-tickets:positions 0 9
```

---

### 4. Position Metadata

**Key:** `position:{position_id}`
**Type:** HASH
**TTL:** 30 minutes (refreshed on heartbeat)

```
Fields:
  queue_id          string    "concert-tickets"
  session_id        string    "sess-abc123"
  status            string    "waiting"    # waiting|admitted|active|expired|completed
  priority          int       "0"
  enqueued_at       int       "1704067200"
  last_heartbeat    int       "1704067260"
  ip_address        string    "192.168.1.1"
  ip_hash           string    "a1b2c3d4e5f6"
  user_agent        string    "Mozilla/5.0..."
  metadata          string    "{\"user_id\":\"123\"}"  # JSON string
```

**Commands:**
```redis
# Create position
HSET position:550e8400-e29b-41d4-a716 queue_id "concert-tickets" status "waiting" ...

# Set TTL
EXPIRE position:550e8400-e29b-41d4-a716 1800

# Get single field
HGET position:550e8400-e29b-41d4-a716 status

# Get all fields
HGETALL position:550e8400-e29b-41d4-a716

# Update heartbeat
HSET position:550e8400-e29b-41d4-a716 last_heartbeat 1704067260

# Update status
HSET position:550e8400-e29b-41d4-a716 status "admitted"
```

---

### 5. Session Data

**Key:** `session:{session_id}`
**Type:** HASH
**TTL:** 1 hour (configurable per queue)

```
Fields:
  queue_id          string    "concert-tickets"
  position_id       string    "550e8400-e29b-41d4-a716"
  user_id           string    "user-123"           # Optional
  ip_address        string    "192.168.1.1"
  user_agent        string    "Mozilla/5.0..."
  token             string    "eyJhbGciOiJSUzI1NiIs..."
  started_at        int       "1704067200"
  expires_at        int       "1704070800"
  last_activity     int       "1704067260"
  page_views        int       "5"
  status            string    "active"    # active|expired|terminated
```

**Commands:**
```redis
# Create session
HSET session:a1b2c3d4-e5f6-7890 queue_id "concert-tickets" position_id "550e8400..." ...

# Set TTL
EXPIRE session:a1b2c3d4-e5f6-7890 3600

# Update activity
HSET session:a1b2c3d4-e5f6-7890 last_activity 1704067260
HINCRBY session:a1b2c3d4-e5f6-7890 page_views 1

# Get session
HGETALL session:a1b2c3d4-e5f6-7890
```

---

### 6. Active Sessions Index

**Key:** `queue:{queue_id}:sessions:active`
**Type:** SET
**TTL:** None

```
Members: session_id

Used for:
- Counting active sessions
- Finding all active sessions for a queue
```

**Commands:**
```redis
# Add session
SADD queue:concert-tickets:sessions:active "a1b2c3d4-e5f6-7890"

# Remove session
SREM queue:concert-tickets:sessions:active "a1b2c3d4-e5f6-7890"

# Count active sessions
SCARD queue:concert-tickets:sessions:active

# Get all active sessions
SMEMBERS queue:concert-tickets:sessions:active
```

---

### 7. Heartbeat Tracking

**Key:** `heartbeat:active`
**Type:** ZSET (Sorted Set)
**TTL:** None

```
Member: position_id
Score:  last_heartbeat_timestamp (Unix seconds)

Used for:
- Efficient expiry detection
- Finding stale positions
```

**Commands:**
```redis
# Register/update heartbeat
ZADD heartbeat:active 1704067260 "550e8400-e29b-41d4-a716"

# Find expired positions (score < cutoff)
ZRANGEBYSCORE heartbeat:active -inf 1704067200

# Remove expired positions
ZREMRANGEBYSCORE heartbeat:active -inf 1704067200

# Count active heartbeats
ZCARD heartbeat:active
```

---

### 8. Rate Limiting (Sliding Window)

**Key:** `ratelimit:{identifier}:{action}`
**Type:** ZSET (Sorted Set)
**TTL:** 1 minute (window size)

```
Member: unique_request_id (UUID)
Score:  timestamp (Unix milliseconds)

Used for:
- Sliding window rate limiting
- Per-IP, per-user, per-token limits
```

**Commands:**
```redis
# Add request
ZADD ratelimit:192.168.1.1:enqueue 1704067260000 "req-uuid-1"

# Remove old entries (outside window)
ZREMRANGEBYSCORE ratelimit:192.168.1.1:enqueue -inf 1704067200000

# Count requests in window
ZCARD ratelimit:192.168.1.1:enqueue

# Set TTL
EXPIRE ratelimit:192.168.1.1:enqueue 60
```

---

### 9. Token Revocation List

**Key:** `revocation:{token_id}`
**Type:** STRING
**TTL:** Remaining token TTL

```
Value: reason for revocation

Examples:
- "abuse_detected"
- "admin_revoked"
- "session_terminated"
```

**Commands:**
```redis
# Revoke token
SET revocation:550e8400-e29b-41d4-a716 "abuse_detected" EX 1800

# Check if revoked
GET revocation:550e8400-e29b-41d4-a716

# Check existence
EXISTS revocation:550e8400-e29b-41d4-a716
```

---

### 10. Admission Tokens (Token Bucket)

**Key:** `admission:{queue_id}:tokens`
**Type:** STRING
**TTL:** None

```
Value: current token count
```

**Key:** `admission:{queue_id}:last_update`
**Type:** STRING
**TTL:** None

```
Value: last refill timestamp (Unix seconds)
```

**Commands:**
```redis
# Initialize
SET admission:concert-tickets:tokens 1000
SET admission:concert-tickets:last_update 1704067200

# Consume token
DECR admission:concert-tickets:tokens

# Return token (on error)
INCR admission:concert-tickets:tokens

# Get current tokens
GET admission:concert-tickets:tokens
```

---

### 11. IP-to-Position Mapping

**Key:** `ipmap:{queue_id}:{ip_hash}`
**Type:** STRING
**TTL:** Same as position TTL

```
Value: position_id

Used for:
- Preventing duplicate positions from same IP
- Finding existing position on reconnect
```

**Commands:**
```redis
# Map IP to position
SET ipmap:concert-tickets:a1b2c3d4e5f6 "550e8400-e29b-41d4-a716" EX 1800

# Find position by IP
GET ipmap:concert-tickets:a1b2c3d4e5f6
```

---

### 12. Queue Statistics

**Key:** `stats:{queue_id}:hourly:{hour}`
**Type:** HASH
**TTL:** 24 hours

```
Fields:
  total_enqueued    int       "15000"
  total_admitted    int       "5000"
  total_expired     int       "200"
  avg_wait_time     int       "120"    # seconds
  peak_queue_size   int       "12000"
```

**Commands:**
```redis
# Increment counters
HINCRBY stats:concert-tickets:hourly:2024010112 total_enqueued 1
HINCRBY stats:concert-tickets:hourly:2024010112 total_admitted 1

# Update peak
HSET stats:concert-tickets:hourly:2024010112 peak_queue_size 12000

# Get stats
HGETALL stats:concert-tickets:hourly:2024010112
```

---

## TTL Policies

| Key Pattern | TTL | Refresh Policy |
|-------------|-----|----------------|
| `position:*` | 30 min | Refreshed on heartbeat |
| `session:*` | 1 hour | Refreshed on activity |
| `heartbeat:active` | None | Members removed on cleanup |
| `ratelimit:*` | 1 min | Auto-expire |
| `revocation:*` | Token TTL | Set at revocation time |
| `ipmap:*` | 30 min | Same as position |
| `stats:*:hourly:*` | 24 hours | No refresh |

---

## Lua Scripts

### Atomic Enqueue

```lua
-- KEYS[1] = queue:{queue_id}:waiting:{priority}
-- KEYS[2] = queue:{queue_id}:positions
-- KEYS[3] = position:{position_id}
-- KEYS[4] = ipmap:{queue_id}:{ip_hash}
-- KEYS[5] = heartbeat:active
-- ARGV[1] = position_id
-- ARGV[2] = timestamp (microseconds)
-- ARGV[3] = ip_hash
-- ARGV[4] = position TTL (seconds)
-- ARGV[5] = metadata JSON

-- Check for existing position by IP
local existing = redis.call('GET', KEYS[4])
if existing then
    return {0, existing}  -- Return existing position
end

-- Add to queue list
redis.call('RPUSH', KEYS[1], ARGV[1])

-- Add to sorted set for position tracking
redis.call('ZADD', KEYS[2], ARGV[2], ARGV[1])

-- Create position metadata
redis.call('HSET', KEYS[3],
    'status', 'waiting',
    'enqueued_at', ARGV[2],
    'last_heartbeat', ARGV[2],
    'metadata', ARGV[5]
)
redis.call('EXPIRE', KEYS[3], ARGV[4])

-- Map IP to position
redis.call('SET', KEYS[4], ARGV[1], 'EX', ARGV[4])

-- Add to heartbeat tracking
redis.call('ZADD', KEYS[5], math.floor(ARGV[2] / 1000000), ARGV[1])

return {1, ARGV[1]}  -- Success, return position_id
```

### Atomic Dequeue

```lua
-- KEYS[1-4] = queue:{queue_id}:waiting:{0-3} (all priority levels)
-- KEYS[5] = queue:{queue_id}:positions
-- KEYS[6] = queue:{queue_id}:sessions:active
-- ARGV[1] = session_id
-- ARGV[2] = timestamp

-- Try each priority level
for i = 1, 4 do
    local position_id = redis.call('LPOP', KEYS[i])
    if position_id then
        -- Remove from sorted set
        redis.call('ZREM', KEYS[5], position_id)
        
        -- Update position status
        redis.call('HSET', 'position:' .. position_id,
            'status', 'admitted',
            'session_id', ARGV[1],
            'admitted_at', ARGV[2]
        )
        
        -- Add to active sessions
        redis.call('SADD', KEYS[6], ARGV[1])
        
        return position_id
    end
end

return nil  -- Queue empty
```

### Heartbeat Update

```lua
-- KEYS[1] = position:{position_id}
-- KEYS[2] = heartbeat:active
-- ARGV[1] = position_id
-- ARGV[2] = timestamp (seconds)
-- ARGV[3] = TTL (seconds)

-- Check position exists
if redis.call('EXISTS', KEYS[1]) == 0 then
    return 0  -- Position not found
end

-- Update heartbeat timestamp
redis.call('HSET', KEYS[1], 'last_heartbeat', ARGV[2])
redis.call('EXPIRE', KEYS[1], ARGV[3])

-- Update sorted set
redis.call('ZADD', KEYS[2], ARGV[2], ARGV[1])

return 1  -- Success
```

### Cleanup Expired

```lua
-- KEYS[1] = heartbeat:active
-- KEYS[2] = queue:{queue_id}:positions
-- ARGV[1] = cutoff timestamp
-- ARGV[2] = batch size

-- Get expired positions
local expired = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', ARGV[1], 'LIMIT', 0, ARGV[2])

if #expired == 0 then
    return {}
end

-- Process each expired position
for _, position_id in ipairs(expired) do
    -- Remove from heartbeat tracking
    redis.call('ZREM', KEYS[1], position_id)
    
    -- Remove from positions sorted set
    redis.call('ZREM', KEYS[2], position_id)
    
    -- Update position status
    redis.call('HSET', 'position:' .. position_id, 'status', 'expired')
end

return expired
```

---

## Memory Estimation

### Per Position

```
Position metadata (HASH):     ~500 bytes
Queue list entry (LIST):      ~40 bytes
Sorted set entry (ZSET):      ~50 bytes
Heartbeat entry (ZSET):       ~50 bytes
IP mapping (STRING):          ~60 bytes
Total per position:           ~700 bytes
```

### Per Session

```
Session data (HASH):          ~600 bytes
Active sessions set (SET):    ~40 bytes
Total per session:            ~640 bytes
```

### Example: 100,000 users in queue

```
Positions:  100,000 × 700 bytes = 70 MB
Sessions:   1,000 × 640 bytes = 0.64 MB
Rate limits: ~10 MB
Total:      ~81 MB
```

DragonFlyDB can easily handle millions of concurrent positions in memory.
