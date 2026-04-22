# 47 — Toxiproxy Introduction

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Set up Toxiproxy — Shopify's lightweight TCP proxy with a REST API for injecting network toxics — and proxy your Go application's PostgreSQL connection through it.

## Architecture

```
target-app (Go)
    │
    │ connects to :5432 (Toxiproxy)
    ▼
[Toxiproxy proxy]
    │
    │ forwards to :5433 (real Postgres)
    ▼
postgres:5433
```

## Step 1: Start Toxiproxy via Docker Compose

The series `docker-compose.yml` already includes Toxiproxy. Start it:

```bash
docker compose up -d toxiproxy postgres
```

## Step 2: Create a Toxiproxy proxy via API

```bash
# Create proxy: listen on :5432, upstream to postgres:5433
curl -XPOST http://localhost:8474/proxies \
  -H "Content-Type: application/json" \
  -d '{
    "name":     "postgres",
    "listen":   "0.0.0.0:5432",
    "upstream": "postgres:5432"
  }'
```

## Step 3: Connect your Go app through Toxiproxy

```go
package main

import (
    "database/sql"
    "fmt"
    "log"

    _ "github.com/lib/pq"
)

func main() {
    // Connect through Toxiproxy, NOT directly to postgres
    connStr := "host=localhost port=5432 user=chaos password=chaos123 dbname=chaosdb sslmode=disable"
    db, err := sql.Open("postgres", connStr)
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    var result int
    err = db.QueryRow("SELECT 1").Scan(&result)
    fmt.Printf("DB ping result: %d, err: %v\n", result, err)
}
```

## Step 4: Verify the proxy works

```bash
go run main.go
# DB ping result: 1, err: <nil>
```

## Step 5: List all proxies

```bash
curl http://localhost:8474/proxies | jq
```

## Toxiproxy CLI (toxiproxy-cli)

```bash
# List proxies
toxiproxy-cli list

# Show proxy details
toxiproxy-cli inspect postgres

# Enable/disable proxy
toxiproxy-cli toggle postgres
```

## Toxiproxy toxic types overview

| Toxic | Effect |
|-------|--------|
| `latency` | Add delay (ms) to data passing through |
| `bandwidth` | Throttle throughput (KB/s) |
| `slow_close` | Delay TCP `FIN` |
| `timeout` | Cut connection after N ms |
| `reset_peer` | Send TCP RST immediately |
| `slicer` | Slice data into smaller chunks |
| `limit_data` | Close after N bytes |

---
*Part of the 100-Lesson Chaos Engineering Series.*
