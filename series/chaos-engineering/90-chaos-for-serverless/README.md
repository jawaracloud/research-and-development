# 90 — Chaos for Serverless

> **Type:** How-To  
> **Phase:** Advanced Topics & GameDay

## Overview

This lesson explores chaos engineering patterns for serverless and FaaS (Function-as-a-Service) architectures — AWS Lambda, Google Cloud Functions, or Knative — where you don't control the underlying infrastructure.

## Serverless Chaos Constraints

| Traditional K8s chaos | Serverless chaos |
|----------------------|-----------------|
| Pod delete → test recovery | Function throttling → test queue backpressure |
| Node drain → test scheduling | Function timeout → test caller retry logic |
| Network partition → test isolation | Cold start latency → test timeout budgets |
| Memory hog → test OOM | Memory limit → test function behaviour near limit |

## Method 1: AWS Lambda — inject chaos via wrapper

The **chaos-lambda** pattern wraps your handler with a fault injector:

```go
// chaos/lambda_wrapper.go
package chaos

import (
    "context"
    "math/rand"
    "time"
)

type ChaosConfig struct {
    FailureRate    float64       // 0.0–1.0
    LatencyMs      int
    FailureMessage string
}

func WithChaos(cfg ChaosConfig, handler func(context.Context, interface{}) error) func(context.Context, interface{}) error {
    return func(ctx context.Context, event interface{}) error {
        // Inject latency
        if cfg.LatencyMs > 0 {
            time.Sleep(time.Duration(cfg.LatencyMs) * time.Millisecond)
        }

        // Inject failures
        if rand.Float64() < cfg.FailureRate {
            return fmt.Errorf(cfg.FailureMessage)
        }

        return handler(ctx, event)
    }
}
```

```go
// main.go — activated via env var
cfg := chaos.ChaosConfig{}
if os.Getenv("CHAOS_ENABLED") == "true" {
    cfg.FailureRate = 0.1    // 10% failures
    cfg.LatencyMs = 500      // 500ms added latency
}
lambda.Start(chaos.WithChaos(cfg, myHandler))
```

## Method 2: AWS Lambda — throttling simulation

```bash
# Set a low reserved concurrency to force throttling
aws lambda put-function-concurrency \
  --function-name my-processor \
  --reserved-concurrent-executions 1

# Generate high request volume
for i in $(seq 1 50); do
  aws lambda invoke --function-name my-processor \
    --payload '{}' /dev/null --async
done

# Watch throttle metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Throttles \
  --dimensions Name=FunctionName,Value=my-processor
```

## Method 3: Knative Function chaos with Chaos Mesh

```yaml
# Target Knative Function pods directly
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: knative-func-chaos
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces: [knative-serving]
    labelSelectors:
      "serving.knative.dev/service": "my-function"
  duration: "30s"
```

## Key resilience patterns for serverless

| Pattern | Implementation |
|---------|---------------|
| Idempotent handlers | Deduplication key in SQS/EventBridge |
| Dead letter queues | `--destination-config OnFailure=DLQ` |
| X-Ray tracing | `aws-xray-sdk-go` |
| Retry with exponential backoff | SQS visibility timeout |

---
*Part of the 100-Lesson Chaos Engineering Series.*
