# 49 — Toxiproxy Timeout

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Add a `timeout` toxic to Toxiproxy to drop connections after a specified period, simulating a connection that hangs mid-query — a common failure mode when upstream services are unresponsive.

**Hypothesis**: When PostgreSQL connections are dropped after 500 ms, the Go application detects the timeout via context deadline and returns a `503` with a useful error message within 1 second — no goroutine leak, no connection pool exhaustion.

## Step 1: Add the timeout toxic

```bash
curl -XPOST http://localhost:8474/proxies/postgres/toxics \
  -H "Content-Type: application/json" \
  -d '{
    "name":       "db-timeout",
    "type":       "timeout",
    "stream":     "downstream",
    "toxicity":   1.0,
    "attributes": {
      "timeout": 500
    }
  }'
```

The connection is closed after **500 ms** with no data sent back.

## Step 2: Go application with context deadline

```go
func queryWithTimeout(db *sql.DB) error {
    ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
    defer cancel()

    var result int
    err := db.QueryRowContext(ctx, "SELECT pg_sleep(10)").Scan(&result)
    if errors.Is(err, context.DeadlineExceeded) {
        return fmt.Errorf("database query timed out: %w", err)
    }
    if err != nil {
        return fmt.Errorf("database error: %w", err)
    }
    return nil
}
```

## Step 3: Verify timeout is caught

```bash
go run main.go
# 2026/03/14 06:00:00 database query timed out: context deadline exceeded
```

## Step 4: Compare `timeout` vs `reset_peer` toxic

| Toxic | TCP Behavior | Application View |
|-------|-------------|-----------------|
| `timeout` | Silent close after N ms | `io.EOF` or deadline exceeded |
| `reset_peer` | Immediate TCP RST | `connection reset by peer` |
| `slow_close` | Delay FIN | Slow close acknowledgement |

```bash
# Switch to reset_peer for instant failure
curl -XPOST http://localhost:8474/proxies/postgres/toxics \
  -d '{"name":"db-reset","type":"reset_peer","attributes":{"timeout":0}}'
```

## Checking for goroutine leaks

```go
// In your test suite, use goleak to detect goroutine leaks
import "go.uber.org/goleak"

func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}
```

After the timeout, all goroutines blocked on `QueryRowContext` should have returned.

---
*Part of the 100-Lesson Chaos Engineering Series.*
