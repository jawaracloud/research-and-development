# 50 — Toxiproxy Bandwidth

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Add a `bandwidth` toxic to throttle throughput between your application and the database, simulating a low-bandwidth WAN link, a saturated network interface, or traffic shaping in a restricted environment.

**Hypothesis**: When database connection bandwidth is throttled to 56 KB/s (simulating a slow link), queries returning large result sets take proportionally longer, but small health-check queries remain fast (< 100 ms).

## Step 1: Add the bandwidth toxic

```bash
curl -XPOST http://localhost:8474/proxies/postgres/toxics \
  -H "Content-Type: application/json" \
  -d '{
    "name":       "db-bandwidth",
    "type":       "bandwidth",
    "stream":     "downstream",
    "toxicity":   1.0,
    "attributes": {
      "rate": 56
    }
  }'
```

`rate`: KB/s. `56` = ~56 kbps dial-up speed.

## Step 2: Test with large and small queries

```go
package main

import (
    "database/sql"
    "fmt"
    "log"
    "time"
    _ "github.com/lib/pq"
)

func main() {
    db, _ := sql.Open("postgres",
        "host=localhost port=5432 user=chaos password=chaos123 dbname=chaosdb sslmode=disable")

    // Small query — should be fast even under bandwidth constraint
    start := time.Now()
    var one int
    db.QueryRow("SELECT 1").Scan(&one)
    fmt.Printf("tiny query: %v\n", time.Since(start))

    // Large query — will be throttled
    start = time.Now()
    rows, _ := db.Query("SELECT repeat('x', 1024) FROM generate_series(1, 1000)")
    defer rows.Close()
    count := 0
    for rows.Next() { count++ }
    fmt.Printf("large query (%d rows, ~1MB): %v\n", count, time.Since(start))
}
```

Expected output:
```
tiny query:   3ms     ← small payload, barely affected
large query:  ~145s   ← 1 MB at 56 KB/s = ~18s (+ protocol overhead)
```

## Step 3: Pagination as a resilience pattern

Under bandwidth constraints, stream or paginate large results:

```go
// Instead of SELECT all, paginate
const pageSize = 100
for offset := 0; ; offset += pageSize {
    rows, err := db.QueryContext(ctx,
        "SELECT id, name FROM users ORDER BY id LIMIT $1 OFFSET $2",
        pageSize, offset)
    if err != nil { break }
    // process page...
    if rowCount < pageSize { break }
}
```

## Bandwidth toxic on different streams

| Stream | What it throttles |
|--------|------------------|
| `downstream` | Data from Postgres → app |
| `upstream` | Queries from app → Postgres |
| Both (add two toxics) | Both directions |

## Remove toxic

```bash
curl -XDELETE http://localhost:8474/proxies/postgres/toxics/db-bandwidth
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
