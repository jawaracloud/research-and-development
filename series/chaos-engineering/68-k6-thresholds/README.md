# 68 — k6 Thresholds as Hypothesis Gates

> **Type:** How-To  
> **Phase:** Observability & Automation

## Overview

k6 **thresholds** are pass/fail criteria that map directly to your steady-state hypothesis. When chaos causes a threshold breach, k6 exits with a non-zero status code — making it a perfect CI gate for chaos experiments.

## Threshold ↔ Hypothesis Mapping

| Hypothesis | k6 Threshold |
|-----------|-------------|
| Error rate < 1% | `error_rate: ['rate<0.01']` |
| p99 latency < 500ms | `http_req_duration: ['p(99)<500']` |
| All responses 200 | `checks: ['rate>0.99']` |
| Throughput > 100 rps | `http_reqs: ['rate>100']` |

## Step 1: Comprehensive threshold script

`hypothesis-gates.js`:

```js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errors = new Rate('errors');

export const options = {
  vus: 10,
  duration: '120s',
  thresholds: {
    // Primary SLO thresholds
    'http_req_duration': [
      'p(99)<500',       // 99th percentile < 500ms
      'p(95)<300',       // 95th percentile < 300ms
      'avg<200',         // average < 200ms
    ],
    'errors': ['rate<0.01'],      // error rate < 1%
    'checks': ['rate>0.99'],      // >99% checks pass

    // Per-endpoint thresholds
    'http_req_duration{url:http://target-app:8080/health}': ['p(99)<100'],
    'http_req_duration{url:http://target-app:8080/echo}': ['p(99)<500'],
  },
};

export default function () {
  const health = http.get('http://target-app:8080/health',
    { tags: { url: 'http://target-app:8080/health' } });
  const echo  = http.get('http://target-app:8080/echo',
    { tags: { url: 'http://target-app:8080/echo' } });

  const ok = check(health, { 'health: 200': r => r.status === 200 });
  errors.add(!ok);
  sleep(0.1);
}
```

## Step 2: Use exit code in CI

```bash
k6 run hypothesis-gates.js
EXIT_CODE=$?

if [ "$EXIT_CODE" -ne 0 ]; then
  echo "❌ Hypothesis FAILED — k6 thresholds breached"
  # Abort chaos experiment
  kubectl patch chaosengine first-pod-delete -n litmus \
    --type=merge -p '{"spec":{"engineState":"stop"}}'
  exit 1
fi
echo "✅ Hypothesis PASSED — all k6 thresholds met"
```

## Step 3: Time-bounded thresholds

Only enforce thresholds after the system has had time to stabilise:

```js
export const options = {
  thresholds: {
    'http_req_duration': [{
      threshold: 'p(99)<500',
      abortOnFail: true,
      delayAbortEval: '30s',   // don't abort for first 30s (warm-up)
    }],
  },
};
```

## abortOnFail — automatic k6 abort

```js
thresholds: {
  'errors': [{
    threshold: 'rate<0.05',
    abortOnFail: true,        // stop the test immediately if > 5% errors
  }],
}
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
