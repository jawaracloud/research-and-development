# 08 — Target Application

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

A simple Go HTTP service that serves as the **chaos target** throughout this series. It exposes health, readiness, and metrics endpoints, and simulates realistic traffic patterns.

## Project layout

```
08-target-application/
├── main.go
├── go.mod
└── k8s/
    ├── deployment.yaml
    └── service.yaml
```

## Step 1: The Go application

`main.go`:

```go
package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
    "time"

    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    requestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{Name: "http_requests_total", Help: "Total HTTP requests"},
        []string{"method", "path", "status"},
    )
    requestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "HTTP request duration",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "path"},
    )
)

func init() {
    prometheus.MustRegister(requestsTotal, requestDuration)
}

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    mux := http.NewServeMux()
    mux.HandleFunc("/health",   healthHandler)
    mux.HandleFunc("/ready",    readyHandler)
    mux.HandleFunc("/echo",     echoHandler)
    mux.Handle("/metrics",      promhttp.Handler())

    log.Printf("Starting chaos target on :%s", port)
    log.Fatal(http.ListenAndServe(":"+port, mux))
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprintln(w, `{"status":"ok"}`)
}

func readyHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprintln(w, `{"ready":true}`)
}

func echoHandler(w http.ResponseWriter, r *http.Request) {
    start := time.Now()
    msg := r.URL.Query().Get("msg")
    if msg == "" {
        msg = "hello from chaos target"
    }
    w.WriteHeader(http.StatusOK)
    fmt.Fprintln(w, msg)
    requestDuration.WithLabelValues(r.Method, r.URL.Path).Observe(time.Since(start).Seconds())
    requestsTotal.WithLabelValues(r.Method, r.URL.Path, "200").Inc()
}
```

## Step 2: Kubernetes manifests

`k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: target-app
  namespace: default
  labels:
    app: target-app
  annotations:
    litmuschaos.io/chaos: "true"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: target-app
  template:
    metadata:
      labels:
        app: target-app
    spec:
      containers:
        - name: target-app
          image: golang:1.23-alpine
          ports:
            - containerPort: 8080
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
            limits:
              cpu: 500m
              memory: 128Mi
```

## Step 3: Deploy

```bash
kubectl apply -f k8s/
kubectl rollout status deployment/target-app
```

## Step 4: Verify

```bash
# Port-forward and test
kubectl port-forward svc/target-app 8080:80 &
curl http://localhost:8080/health
# {"status":"ok"}

curl http://localhost:8080/metrics | grep http_requests_total
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
