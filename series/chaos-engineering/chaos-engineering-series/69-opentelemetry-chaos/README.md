# 69 — OpenTelemetry Chaos Observability

> **Type:** Tutorial  
> **Phase:** Observability & Automation

## What you're building

Extend the target-app OpenTelemetry instrumentation to tag traces and metrics with chaos experiment context, enabling precise filtering and analysis of chaos impact in Jaeger and Grafana.

## Chaos Context Propagation

During chaos experiments, inject chaos context as OTel attributes and Prometheus labels so every metric and trace can be correlated to the running experiment.

## Step 1: Chaos context injector (Go)

```go
package chaos

import (
    "context"
    "os"

    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/trace"
)

type ChaosContext struct {
    ExperimentName string
    EngineContext  string
    Active         bool
}

func GetChaosContext() ChaosContext {
    return ChaosContext{
        ExperimentName: os.Getenv("CHAOSENGINE"),      // set by LitmusChaos
        EngineContext:  os.Getenv("CHAOS_NAMESPACE"),
        Active:         os.Getenv("CHAOS_MARKER") != "",
    }
}

func TagSpanWithChaos(span trace.Span, c ChaosContext) {
    if c.Active {
        span.SetAttributes(
            attribute.String("chaos.experiment", c.ExperimentName),
            attribute.String("chaos.namespace", c.EngineContext),
            attribute.Bool("chaos.active", true),
        )
    }
}
```

## Step 2: Inject chaos env vars via LitmusChaos

```yaml
# In ChaosEngine spec
spec:
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: CHAOS_MARKER
              value: "1"
            - name: CHAOSENGINE
              value: "first-pod-delete"
```

## Step 3: OTel resource attributes at startup

```go
res, _ := resource.New(context.Background(),
    resource.WithAttributes(
        semconv.ServiceName("target-app"),
        semconv.ServiceVersion("1.0.0"),
        attribute.String("deployment.environment", "chaos-lab"),
    ),
)
```

## Step 4: Prometheus exemplars linking metrics to traces

```go
// Attach trace ID as Prometheus exemplar
histogram.With(prometheus.Labels{"status": "200"}).
    ObserveWithExemplar(
        duration,
        prometheus.Labels{"traceID": span.SpanContext().TraceID().String()},
    )
```

## Step 5: Grafana Tempo — traces linked from metrics

In Grafana → Explore → Prometheus, query:
```promql
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[1m]))
```

Click any data point → **"Query with Tempo"** → see all traces from that second with TraceID exemplars.

---
*Part of the 100-Lesson Chaos Engineering Series.*
