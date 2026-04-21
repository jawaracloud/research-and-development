# 67 — k6 Load During Chaos

> **Type:** Tutorial  
> **Phase:** Observability & Automation

## What you're building

Run a k6 load test simultaneously with a chaos experiment to observe how real traffic behaves under fault injection — a more realistic picture than probes alone.

## Why run load alongside chaos?

- Probes test single requests; load tests reveal queue depth and pool exhaustion
- Load amplifies the blast radius: 10 VUs × pod restart = 10 in-flight failures
- k6 thresholds act as an automatic experiment guard

## Step 1: k6 load test script

`load-test.js`:

```js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('error_rate');
const chaosLatency = new Trend('chaos_latency');

export const options = {
  stages: [
    { duration: '30s', target: 10 },   // ramp up
    { duration: '120s', target: 10 },  // hold — chaos injected here
    { duration: '30s', target: 0 },    // ramp down
  ],
  thresholds: {
    'error_rate':   ['rate<0.01'],     // < 1% errors
    'http_req_duration': ['p(99)<500'], // p99 < 500ms
    'chaos_latency': ['p(99)<1000'],   // chaos hypothesis
  },
};

export default function () {
  const res = http.get('http://target-app.default.svc.cluster.local:8080/echo');

  const ok = check(res, {
    'status 200': (r) => r.status === 200,
  });

  errorRate.add(!ok);
  chaosLatency.add(res.timings.duration);

  sleep(0.1);
}
```

## Step 2: Run k6 alongside chaos

```bash
# Terminal 1 — start k6
k6 run load-test.js

# Terminal 2 — inject chaos (pod delete)
kubectl apply -f ../11-first-pod-delete/pod-delete-engine.yaml

# Terminal 3 — watch chaos result
kubectl get chaosresult -n litmus -w
```

## Step 3: k6 summary output

```
✓ status 200

Scenario: default
  VUs:          10
  Duration:     3m0s

  error_rate.......: 0.42% ✓ < 1%
  http_req_duration: avg=87ms  p(90)=154ms  p(99)=432ms ✓
  chaos_latency....: avg=87ms  p(99)=432ms ✓

✓ 1 thresholds passed
```

## Step 4: Export k6 metrics to Prometheus

```bash
# Run k6 with Prometheus output
k6 run --out=experimental-prometheus-rw load-test.js

# Prometheus remote write endpoint:
export K6_PROMETHEUS_RW_SERVER_URL=http://localhost:9090/api/v1/write
```

Now k6 metrics appear in Grafana alongside Prometheus chaos metrics.

---
*Part of the 100-Lesson Chaos Engineering Series.*
