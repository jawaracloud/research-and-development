# Heartbeat Mechanism Design

## Overview

The heartbeat mechanism ensures that inactive users are removed from the queue, freeing up positions for active users. It provides a balance between responsiveness and resource efficiency.

---

## Core Concepts

### Heartbeat Flow

```
Client                              Server
  |                                   |
  |-------- Enqueue Request --------->|
  |<------- Position + Token ---------|
  |                                   |
  |-------- Heartbeat #1 ------------>| (at 10s)
  |<------- Ack + Updated Position ---|
  |                                   |
  |-------- Heartbeat #2 ------------>| (at 20s)
  |<------- Ack + Updated Position ---|
  |                                   |
  |        ... (user closes browser)  |
  |                                   |
  |                                   | (timeout at 60s)
  |                                   | [Remove from queue]
  |                                   |
```

### Timing Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `heartbeat_interval` | 10s | How often client sends heartbeat |
| `heartbeat_timeout` | 60s | Time without heartbeat before removal |
| `grace_period` | 30s | Extra time for network issues |
| `cleanup_interval` | 5s | How often server checks for expired positions |

---

## Client-Side Implementation

### JavaScript Heartbeat Client

```javascript
class WaitingRoomClient {
    constructor(options) {
        this.token = options.token;
        this.heartbeatUrl = options.heartbeatUrl;
        this.statusUrl = options.statusUrl;
        this.interval = options.interval || 10000; // 10s default
        this.timeout = options.timeout || 60000;   // 60s default
        this.timerId = null;
        this.lastResponse = null;
        this.onPositionUpdate = options.onPositionUpdate || (() => {});
        this.onAdmitted = options.onAdmitted || (() => {});
        this.onExpired = options.onExpired || (() => {});
        this.onError = options.onError || (() => {});
    }

    start() {
        // Initial status check
        this.checkStatus();
        
        // Start heartbeat loop
        this.timerId = setInterval(() => {
            this.sendHeartbeat();
        }, this.interval);
        
        // Visibility change handling
        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'visible') {
                this.sendHeartbeat(); // Immediate heartbeat on tab focus
            }
        });
        
        // Page unload handling
        window.addEventListener('beforeunload', () => {
            this.sendBeacon(); // Best-effort notification
        });
    }

    stop() {
        if (this.timerId) {
            clearInterval(this.timerId);
            this.timerId = null;
        }
    }

    async sendHeartbeat() {
        try {
            const response = await fetch(this.heartbeatUrl, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    timestamp: Date.now(),
                    client_id: this.getClientId()
                })
            });

            if (!response.ok) {
                if (response.status === 410) {
                    // Position expired
                    this.stop();
                    this.onExpired();
                    return;
                }
                throw new Error(`HTTP ${response.status}`);
            }

            const data = await response.json();
            this.lastResponse = data;
            this.token = data.token || this.token; // Updated token

            if (data.status === 'admitted') {
                this.stop();
                this.onAdmitted(data.redirect_url, data.session_token);
            } else {
                this.onPositionUpdate(data.position, data.queue_length, data.estimated_wait);
            }
        } catch (error) {
            this.onError(error);
            // Retry logic handled by interval
        }
    }

    async checkStatus() {
        try {
            const response = await fetch(this.statusUrl, {
                headers: {
                    'Authorization': `Bearer ${this.token}`
                }
            });
            
            if (response.ok) {
                const data = await response.json();
                this.onPositionUpdate(data.position, data.queue_length, data.estimated_wait);
            }
        } catch (error) {
            this.onError(error);
        }
    }

    sendBeacon() {
        const data = JSON.stringify({
            token: this.token,
            event: 'page_unload',
            timestamp: Date.now()
        });
        
        navigator.sendBeacon(this.heartbeatUrl, data);
    }

    getClientId() {
        // Generate or retrieve persistent client ID
        let clientId = localStorage.getItem('waiting_room_client_id');
        if (!clientId) {
            clientId = crypto.randomUUID();
            localStorage.setItem('waiting_room_client_id', clientId);
        }
        return clientId;
    }
}

// Usage
const client = new WaitingRoomClient({
    token: 'eyJhbGciOiJSUzI1NiIs...',
    heartbeatUrl: '/api/v1/heartbeat',
    statusUrl: '/api/v1/status',
    onPositionUpdate: (pos, total, wait) => {
        console.log(`Position: ${pos}/${total}, ETA: ${wait}s`);
    },
    onAdmitted: (url, sessionToken) => {
        window.location.href = url;
    },
    onExpired: () => {
        alert('Your position has expired. Please rejoin the queue.');
    }
});

client.start();
```

---

## Server-Side Implementation

### Heartbeat Handler

```go
type HeartbeatHandler struct {
    queueService   *QueueService
    tokenService   *TokenService
    broker         *Broker
    config         HeartbeatConfig
}

type HeartbeatConfig struct {
    Interval       time.Duration `yaml:"interval"`
    Timeout        time.Duration `yaml:"timeout"`
    GracePeriod    time.Duration `yaml:"grace_period"`
    MaxMissed      int           `yaml:"max_missed"`
}

type HeartbeatRequest struct {
    Timestamp int64  `json:"timestamp"`
    ClientID  string `json:"client_id"`
}

type HeartbeatResponse struct {
    Status        string `json:"status"`
    Position      int64  `json:"position"`
    QueueLength   int64  `json:"queue_length"`
    EstimatedWait int64  `json:"estimated_wait_seconds"`
    Token         string `json:"token,omitempty"` // Refreshed token
    RedirectURL   string `json:"redirect_url,omitempty"`
    SessionToken  string `json:"session_token,omitempty"`
}

func (h *HeartbeatHandler) Handle(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    
    // Extract token from Authorization header
    token := extractToken(r)
    if token == "" {
        http.Error(w, "missing token", http.StatusUnauthorized)
        return
    }
    
    // Validate token
    result, err := h.tokenService.ValidateToken(ctx, token, "queue")
    if err != nil {
        if errors.Is(err, ErrTokenExpired) {
            http.Error(w, "token expired", http.StatusGone)
            return
        }
        http.Error(w, "invalid token", http.StatusUnauthorized)
        return
    }
    
    // Parse request body
    var req HeartbeatRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid request", http.StatusBadRequest)
        return
    }
    
    // Record heartbeat
    position, err := h.queueService.RecordHeartbeat(ctx, result.PositionID)
    if err != nil {
        if errors.Is(err, ErrPositionNotFound) {
            http.Error(w, "position not found", http.StatusGone)
            return
        }
        http.Error(w, "internal error", http.StatusInternalServerError)
        return
    }
    
    // Check if user has been admitted
    if position.Status == StatusAdmitted {
        resp := HeartbeatResponse{
            Status:       "admitted",
            RedirectURL:  h.config.RedirectURL,
            SessionToken: position.SessionToken,
        }
        json.NewEncoder(w).Encode(resp)
        return
    }
    
    // Get current position info
    info, err := h.queueService.GetPositionInfo(ctx, result.PositionID)
    if err != nil {
        http.Error(w, "internal error", http.StatusInternalServerError)
        return
    }
    
    // Optionally refresh token
    newToken, _ := h.tokenService.RefreshToken(ctx, token)
    
    // Send response
    resp := HeartbeatResponse{
        Status:        "waiting",
        Position:      info.QueuePosition,
        QueueLength:   info.QueueLength,
        EstimatedWait: int64(info.EstimatedWait.Seconds()),
        Token:         newToken,
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(resp)
}
```

### Heartbeat Recording

```go
func (q *QueueService) RecordHeartbeat(ctx context.Context, positionID string) (*Position, error) {
    // Get position
    position, err := q.store.GetPosition(ctx, positionID)
    if err != nil {
        return nil, fmt.Errorf("getting position: %w", err)
    }
    
    // Check if already admitted or expired
    if position.Status != StatusWaiting {
        return position, nil
    }
    
    // Update last heartbeat timestamp
    now := time.Now()
    position.LastHeartbeat = now
    
    // Store update
    if err := q.store.UpdatePositionHeartbeat(ctx, positionID, now); err != nil {
        return nil, fmt.Errorf("updating heartbeat: %w", err)
    }
    
    // Emit heartbeat event (for monitoring)
    q.broker.Publish(ctx, Event{
        Type:       EventTypeHeartbeat,
        QueueID:    position.QueueID,
        PositionID: positionID,
        Timestamp:  now,
    })
    
    return position, nil
}
```

---

## Timeout Detection

### Cleanup Worker

```go
func (q *QueueService) StartCleanupWorker(ctx context.Context, interval time.Duration) {
    ticker := time.NewTicker(interval)
    defer ticker.Stop()
    
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            q.cleanupExpiredPositions(ctx)
        }
    }
}

func (q *QueueService) cleanupExpiredPositions(ctx context.Context) {
    // Find positions with last_heartbeat > timeout
    cutoff := time.Now().Add(-q.config.HeartbeatTimeout)
    
    // Scan all queues (or use a sorted set for efficient lookup)
    queues, err := q.store.GetAllQueues(ctx)
    if err != nil {
        log.Printf("error getting queues: %v", err)
        return
    }
    
    for _, queueID := range queues {
        expired, err := q.store.FindExpiredPositions(ctx, queueID, cutoff)
        if err != nil {
            log.Printf("error finding expired positions: %v", err)
            continue
        }
        
        for _, pos := range expired {
            q.expirePosition(ctx, pos)
        }
    }
}

func (q *QueueService) expirePosition(ctx context.Context, position *Position) {
    // Remove from queue
    if err := q.store.RemoveFromQueue(ctx, position.QueueID, position.ID); err != nil {
        log.Printf("error removing position %s: %v", position.ID, err)
        return
    }
    
    // Update status
    position.Status = StatusExpired
    position.ExpiredAt = time.Now()
    position.ExpireReason = "heartbeat_timeout"
    
    if err := q.store.UpdatePosition(ctx, position); err != nil {
        log.Printf("error updating position %s: %v", position.ID, err)
    }
    
    // Emit event
    q.broker.Publish(ctx, Event{
        Type:       EventTypeExpired,
        QueueID:    position.QueueID,
        PositionID: position.ID,
        Reason:     "heartbeat_timeout",
        Timestamp:  time.Now(),
    })
    
    // Update metrics
    metrics.PositionsExpired.Inc()
}
```

### Efficient Expiry Lookup

Using Redis Sorted Set for efficient expiry detection:

```go
// On heartbeat, update sorted set
func (s *Store) UpdatePositionHeartbeat(ctx context.Context, positionID string, timestamp time.Time) error {
    pipe := s.redis.Pipeline()
    
    // Update position hash
    pipe.HSet(ctx, fmt.Sprintf("position:%s", positionID), "last_heartbeat", timestamp.Unix())
    
    // Update sorted set (score = last_heartbeat timestamp)
    pipe.ZAdd(ctx, "heartbeats:active", &redis.Z{
        Score:  float64(timestamp.Unix()),
        Member: positionID,
    })
    
    _, err := pipe.Exec(ctx)
    return err
}

// Find expired positions efficiently
func (s *Store) FindExpiredPositions(ctx context.Context, cutoff time.Time) ([]string, error) {
    // Get all positions with score < cutoff
    result, err := s.redis.ZRangeByScore(ctx, "heartbeats:active", &redis.ZRangeBy{
        Min:   "-inf",
        Max:   fmt.Sprintf("%d", cutoff.Unix()),
    }).Result()
    
    if err != nil {
        return nil, err
    }
    
    // Remove from sorted set
    if len(result) > 0 {
        s.redis.ZRem(ctx, "heartbeats:active", result)
    }
    
    return result, nil
}
```

---

## Graceful Degradation

### Network Issue Handling

```go
type HeartbeatState struct {
    LastSuccess    time.Time
    ConsecFailures int
    LastError      error
}

func (h *HeartbeatHandler) HandleWithGrace(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    positionID := getPositionID(r)
    
    // Get current state
    state, err := h.getState(ctx, positionID)
    if err != nil {
        state = &HeartbeatState{}
    }
    
    // Check if in grace period
    if state.ConsecFailures > 0 {
        graceRemaining := h.config.GracePeriod - time.Since(state.LastSuccess)
        if graceRemaining > 0 {
            // Still in grace period, accept heartbeat
            h.resetState(ctx, positionID)
            h.handleSuccess(w, r, positionID)
            return
        }
    }
    
    // Normal processing
    // ...
}

func (h *HeartbeatHandler) handleFailure(ctx context.Context, positionID string, err error) {
    state, _ := h.getState(ctx, positionID)
    state.ConsecFailures++
    state.LastError = err
    h.setState(ctx, positionID, state)
    
    // Only expire after max missed heartbeats
    if state.ConsecFailures >= h.config.MaxMissed {
        h.expirePosition(ctx, positionID)
    }
}
```

### Client Reconnection

```javascript
class WaitingRoomClient {
    // ... existing code ...

    handleReconnect() {
        // Check if we have a stored position
        const storedToken = localStorage.getItem('waiting_room_token');
        const storedPosition = localStorage.getItem('waiting_room_position');
        
        if (storedToken && storedPosition) {
            // Verify token is still valid
            this.verifyAndResume(storedToken, storedPosition);
        }
    }

    async verifyAndResume(token, position) {
        try {
            const response = await fetch(this.statusUrl, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            
            if (response.ok) {
                // Token valid, resume
                this.token = token;
                this.start();
            } else if (response.status === 410) {
                // Position expired, need to rejoin
                this.onExpired();
            } else {
                // Other error, try to rejoin
                this.rejoinQueue();
            }
        } catch (error) {
            this.onError(error);
        }
    }

    persistState() {
        localStorage.setItem('waiting_room_token', this.token);
        localStorage.setItem('waiting_room_position', this.lastResponse?.position || '');
    }
}
```

---

## Metrics & Monitoring

### Prometheus Metrics

```go
var (
    HeartbeatsReceived = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "waiting_room_heartbeats_received_total",
        Help: "Total number of heartbeats received",
    }, []string{"queue_id", "status"})
    
    HeartbeatLatency = promauto.NewHistogramVec(prometheus.HistogramOpts{
        Name: "waiting_room_heartbeat_latency_seconds",
        Help: "Heartbeat processing latency",
        Buckets: []float64{.001, .005, .01, .025, .05, .1, .25, .5, 1},
    }, []string{"queue_id"})
    
    PositionsExpired = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "waiting_room_positions_expired_total",
        Help: "Total positions expired due to heartbeat timeout",
    }, []string{"queue_id", "reason"})
    
    ActiveHeartbeats = promauto.NewGaugeVec(prometheus.GaugeOpts{
        Name: "waiting_room_active_heartbeats",
        Help: "Number of positions with active heartbeats",
    }, []string{"queue_id"})
)
```

### Health Check

```go
func (h *HeartbeatHandler) HealthCheck() error {
    // Check if cleanup worker is running
    if !h.cleanupWorkerRunning {
        return fmt.Errorf("cleanup worker not running")
    }
    
    // Check Redis connectivity
    ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
    defer cancel()
    
    if err := h.store.Ping(ctx); err != nil {
        return fmt.Errorf("store ping failed: %w", err)
    }
    
    return nil
}
```

---

## Configuration

```yaml
heartbeat:
  # Client should send heartbeat every N seconds
  interval: 10s
  
  # Server considers position expired after N seconds without heartbeat
  timeout: 60s
  
  # Extra grace period for network issues
  grace_period: 30s
  
  # Maximum consecutive missed heartbeats before expiry
  max_missed: 3
  
  # How often to run cleanup job
  cleanup_interval: 5s
  
  # Enable/disable heartbeat tracking
  enabled: true
  
  # Token refresh on heartbeat
  refresh_token: true
```
