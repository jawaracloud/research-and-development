# 43 — Chaos Mesh Network Partition

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Use Chaos Mesh's `NetworkChaos` with `partition` action to simulate a network split between two services, testing split-brain handling, connection pooling, and graceful degradation.

**Hypothesis**: When `target-app` is partitioned from the `postgres` database for 30 seconds, the application returns a cached response or a clear error (not a timeout hanging for 30 s), and recovers fully when connectivity restores.

## Step 1: Network partition between target-app and postgres

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: app-db-partition
  namespace: default
spec:
  action: partition
  mode: all
  selector:
    namespaces: [default]
    labelSelectors:
      app: target-app
  direction: both       # bidirectional partition
  target:
    mode: all
    selector:
      namespaces: [default]
      labelSelectors:
        app: postgres
  duration: "30s"
```

```bash
kubectl apply -f network-partition.yaml

# Verify partition in target-app logs
kubectl logs -l app=target-app -n default -f
```

## Step 2: One-directional partition (test asymmetric failure)

```yaml
spec:
  direction: to     # only outgoing packets from target-app to postgres are dropped
```

Options: `to`, `from`, `both`

## What good behavior looks like

```
Request → target-app → Postgres (PARTITIONED)
                      → context.DeadlineExceeded (< 5s timeout)
                      → Return: {"error": "database unavailable", "cached": true}
```

## What bad behavior looks like

```
Request → target-app → Postgres (PARTITIONED)
                      → Wait 30s for TCP timeout
                      → Return: {"error": "timeout"} (user already left)
```

## Implementing connection timeout in Go

```go
db, err := sql.Open("postgres", connStr)
db.SetConnMaxLifetime(5 * time.Second)
db.SetConnMaxIdleTime(2 * time.Second)
// Also set context deadlines per query:

ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()
row := db.QueryRowContext(ctx, "SELECT 1")
if errors.Is(err, context.DeadlineExceeded) {
    // serve from cache or return degraded response
}
```

## Insights this experiment reveals

- Are database connection timeouts set aggressively enough?
- Does your app implement circuit breaking for database connections?
- Does connection pool exhaustion cause cascading failures?

---
*Part of the 100-Lesson Chaos Engineering Series.*
