# 66 — Jaeger Tracing During Chaos

> **Type:** Tutorial  
> **Phase:** Observability & Automation

## What you're building

Instrument `target-app` with OpenTelemetry traces and use Jaeger to observe how distributed traces are affected by chaos injections — identifying exactly which hops in a request are slow or failing.

## Step 1: Install Jaeger

```bash
kubectl create namespace observability
kubectl apply -n observability \
  -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.55.0/jaeger-operator.yaml

# Create a simple all-in-one Jaeger instance
cat <<EOF | kubectl apply -n observability -f -
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
spec:
  strategy: allInOne
EOF

kubectl port-forward svc/jaeger-query 16686:16686 -n observability
```

## Step 2: Instrument target-app with OTel

```go
package main

import (
    "context"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/jaeger"
    "go.opentelemetry.io/otel/sdk/trace"
)

func initTracer() func() {
    exp, _ := jaeger.New(jaeger.WithCollectorEndpoint(
        jaeger.WithEndpoint("http://jaeger-collector.observability:14268/api/traces"),
    ))
    tp := trace.NewTracerProvider(
        trace.WithBatcher(exp),
        trace.WithResource(resource.NewWithAttributes(
            semconv.ServiceName("target-app"),
        )),
    )
    otel.SetTracerProvider(tp)
    return func() { tp.Shutdown(context.Background()) }
}

func handler(w http.ResponseWriter, r *http.Request) {
    ctx, span := otel.Tracer("target-app").Start(r.Context(), "handleEcho")
    defer span.End()

    // DB call with span
    dbCtx, dbSpan := otel.Tracer("target-app").Start(ctx, "db.query")
    err := queryDB(dbCtx)
    dbSpan.End()

    if err != nil {
        span.RecordError(err)
    }
}
```

## Step 3: Inject latency and observe traces

```bash
# Add Toxiproxy 300ms latency to DB
curl -XPOST http://localhost:8474/proxies/postgres/toxics \
  -d '{"name":"latency","type":"latency","attributes":{"latency":300}}'

# Generate some requests
curl http://localhost:8080/echo?msg=tracetest

# Open Jaeger UI: http://localhost:16686
# Find traces for "target-app" service
# The "db.query" span should show 300ms+
```

## What to look for in traces

- **Span duration** of `db.query` → database latency contribution
- **Error flag** on spans → where in the call chain errors originate
- **Missing spans** → service is down (no trace at all)
- **Span tags** → HTTP status, DB query, error message

## Chaos-aware trace tags

```go
span.SetAttributes(
    attribute.String("chaos.experiment", os.Getenv("LITMUS_ENGINE")),
    attribute.Bool("chaos.active", isChaosActive()),
)
```

Tag traces created during chaos windows for post-mortem filtering.

---
*Part of the 100-Lesson Chaos Engineering Series.*
