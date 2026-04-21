# 48 — Toxiproxy Latency Toxic

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Add a `latency` toxic to the Toxiproxy PostgreSQL proxy from lesson 47, simulating a slow or geographically distant database, and measure the application's response under increased DB latency.

**Hypothesis**: When PostgreSQL responds with 200 ms added latency, the Go application's HTTP response time increases proportionally but remains < 500 ms p99, and no connection pool exhaustion occurs.

## Prerequisites

- Toxiproxy running with `postgres` proxy (lesson 47)

## Step 1: Add the latency toxic

```bash
curl -XPOST http://localhost:8474/proxies/postgres/toxics \
  -H "Content-Type: application/json" \
  -d '{
    "name":       "db-latency",
    "type":       "latency",
    "stream":     "downstream",
    "toxicity":   1.0,
    "attributes": {
      "latency": 200,
      "jitter":  20
    }
  }'
```

- `stream: "downstream"` — latency on data coming back from Postgres
- `stream: "upstream"` — latency on queries going to Postgres
- `toxicity` — 0.0–1.0; fraction of connections affected

## Step 2: Verify with a timing test

```bash
# Time a query through the proxy
time psql "host=localhost port=5432 user=chaos password=chaos123 dbname=chaosdb" \
  -c "SELECT 1;"
# real  0m0.215s  ← 200ms of added latency

# Direct to postgres (no proxy)
time psql "host=localhost port=5433 user=chaos password=chaos123 dbname=chaosdb" \
  -c "SELECT 1;"
# real  0m0.005s
```

## Step 3: Measure application impact with k6

```js
// k6-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
export const options = {
  vus: 10,
  duration: '30s',
  thresholds: { 'http_req_duration': ['p(99)<500'] },
};
export default () => {
  const res = http.get('http://localhost:8080/echo');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(0.1);
};
```

```bash
k6 run k6-test.js
```

## Step 4: Remove the toxic

```bash
curl -XDELETE http://localhost:8474/proxies/postgres/toxics/db-latency
```

## Go: connection pool tuning under latency

```go
db.SetMaxOpenConns(25)       // max concurrent connections
db.SetMaxIdleConns(10)       // keep N idle connections ready
db.SetConnMaxLifetime(5 * time.Minute)
db.SetConnMaxIdleTime(2 * time.Minute)
```

Under 200 ms DB latency:
- 10 VUs × 200 ms block = pool exhaustion at ~50 concurrent requests
- Solution: increase `MaxOpenConns` or use async/pipelining

---
*Part of the 100-Lesson Chaos Engineering Series.*
