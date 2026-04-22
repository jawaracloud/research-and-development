# 82 — AWS RDS Failure

> **Type:** Tutorial  
> **Phase:** Advanced Topics & GameDay

## What you're building

Use LitmusChaos's `rds-instance-reboot` experiment to force a failover of an Amazon RDS Multi-AZ instance, validating that your application reconnects to the promoted standby within your RTO.

> **Prerequisites:** Multi-AZ RDS instance, AWS credentials with `rds:RebootDBInstance` permission.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  "https://hub.litmuschaos.io/api/chaos/3.9.0?item=aws/rds-instance-reboot" \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: rds-failover-engine
  namespace: litmus
spec:
  chaosServiceAccount: litmus-admin
  experiments:
    - name: rds-instance-reboot
      spec:
        components:
          env:
            - name: RDS_INSTANCE_IDENTIFIER
              value: "my-prod-rds-instance"
            - name: REGION
              value: "ap-southeast-1"
            - name: TOTAL_CHAOS_DURATION
              value: "120"
            - name: FAILOVER
              value: "true"     # force Multi-AZ failover
          secrets:
            - name: aws-credentials
              mountPath: /tmp/
        probe:
          - name: db-reconnect
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "15s"
              retry: 5
              interval: "10s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/health"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## Step 3: Observe failover timeline

```bash
# Watch RDS events
aws rds describe-events \
  --source-identifier my-prod-rds-instance \
  --source-type db-instance \
  --duration 60 \
  --region ap-southeast-1

# Expected events:
# DB instance failover initiated
# Multi-AZ instance failover completed
# Replication resumed
```

## RDS Multi-AZ Failover Properties

| Property | Typical value |
|----------|--------------|
| Failover duration | 60–120 seconds |
| DNS TTL for endpoint | 60 seconds |
| Connection drop | Brief at failover moment |
| Data loss | None (synchronous replication) |

## Application resilience patterns

```go
// Short max connection lifetime forces reconnection to new endpoint
db.SetConnMaxLifetime(30 * time.Second)

// Detect connection errors and retry
const maxRetries = 5
for attempt := 0; attempt < maxRetries; attempt++ {
    err := db.PingContext(ctx)
    if err == nil { break }
    time.Sleep(time.Duration(attempt+1) * 2 * time.Second)
}
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
