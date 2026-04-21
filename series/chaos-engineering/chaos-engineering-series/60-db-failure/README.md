# 60 — Database Failure

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Combine pod-delete on the PostgreSQL pod (simulating a crash or node failure) with a load test to validate your application's database recovery path — connection pool draining, reconnect logic, and user-facing error messages.

**Hypothesis**: When the PostgreSQL pod is deleted, `target-app` returns `503` with a meaningful error body (not a connection-reset error) within 2 s. When PostgreSQL restarts, the app reconnects automatically and serves requests within 15 s.

## Step 1: Deploy PostgreSQL as a Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: default
  labels:
    app: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:16-alpine
          env:
            - name: POSTGRES_PASSWORD
              value: chaos123
            - name: POSTGRES_DB
              value: chaosdb
          ports:
            - containerPort: 5432
```

## Step 2: Apply LitmusChaos pod-delete

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: postgres-kill
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=postgres"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  annotationCheck: "false"
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: FORCE
              value: "true"          # SIGKILL
            - name: PODS_AFFECTED_PERC
              value: "100"
        probe:
          - name: app-error-handling
            type: httpProbe
            mode: OnChaos
            runProperties:
              probeTimeout: "5s"
              retry: 2
              interval: "5s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/echo"
              method:
                get:
                  criteria: "!="
                  responseCode: "500"   # must not be 500 (should be 503)
```

## Step 3: Monitor recovery

```bash
kubectl apply -f postgres-kill.yaml

# Terminal 1 — watch postgres pod restart
kubectl get pods -l app=postgres -n default -w

# Terminal 2 — watch app logs
kubectl logs -l app=target-app -n default -f | grep -E "error|reconnect|db"

# Terminal 3 — test recovery time
while true; do
  ts=$(date +%T)
  status=$(curl -s -o /dev/null -w "%{http_code}" \
    http://localhost:8080/echo)
  echo "$ts → $status"
  sleep 1
done
```

## Go: database reconnection

`database/sql` reconnects automatically on the next query after a connection is lost — no explicit reconnect logic needed. But you must:

```go
// Set health check interval to detect failures faster
db.SetConnMaxLifetime(5 * time.Minute)

// Use PingContext to verify connection on startup and health checks
if err := db.PingContext(ctx); err != nil {
    http.Error(w, `{"error":"database unavailable"}`, http.StatusServiceUnavailable)
    return
}
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
