# 72 — GitHub Actions Chaos

> **Type:** How-To  
> **Phase:** Observability & Automation

## Overview

Embed a chaos experiment as a step in a GitHub Actions CI/CD workflow — making resilience validation a mandatory gate before production deployment.

## Architecture

```
PR opened → Unit Tests → Build → Deploy to Staging
         → Chaos Experiment → SLO Gate → ✅ → Merge to main
                                        → ❌ → Block merge
```

## Step 1: GitHub Actions workflow

`.github/workflows/chaos-gate.yml`:

```yaml
name: Chaos Resilience Gate

on:
  pull_request:
    branches: [main]

jobs:
  chaos:
    name: Chaos Experiment Gate
    runs-on: ubuntu-latest
    environment: staging

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up kubectl
        uses: azure/setup-kubectl@v4

      - name: Set up kubeconfig
        run: |
          echo "${{ secrets.KUBECONFIG_STAGING }}" | base64 -d > $HOME/.kube/config

      - name: Verify staging cluster health
        run: |
          kubectl get nodes
          kubectl get pods -n default -l app=target-app

      - name: Apply chaos experiment
        run: |
          kubectl apply -f chaos-engineering-series/11-first-pod-delete/pod-delete-engine.yaml

      - name: Wait for chaos to complete
        run: |
          for i in $(seq 1 30); do
            VERDICT=$(kubectl get chaosresult first-pod-delete-pod-delete \
              -n litmus -o jsonpath='{.status.experimentStatus.verdict}' 2>/dev/null || echo "Awaited")
            echo "$(date +%T) Verdict: $VERDICT"
            if [ "$VERDICT" = "Pass" ]; then echo "✅ PASS"; exit 0; fi
            if [ "$VERDICT" = "Fail" ]; then echo "❌ FAIL"; exit 1; fi
            sleep 10
          done
          echo "❌ Timeout waiting for chaos result"
          exit 1

      - name: k6 SLO validation
        run: |
          k6 run chaos-engineering-series/67-k6-load-during-chaos/load-test.js
        env:
          K6_TARGET_URL: ${{ secrets.STAGING_TARGET_URL }}

      - name: Cleanup
        if: always()
        run: |
          kubectl delete chaosengine first-pod-delete -n litmus --ignore-not-found
```

## Step 2: Required GitHub Secrets

| Secret | Value |
|--------|-------|
| `KUBECONFIG_STAGING` | base64-encoded kubeconfig for staging cluster |
| `STAGING_TARGET_URL` | URL of target app on staging |

## Step 3: Branch protection

In GitHub → Repository Settings → Branches → Add rule:
- ✅ Require status checks: `Chaos Resilience Gate`
- ✅ Require branches to be up to date

## Conditional chaos (only on infra changes)

```yaml
on:
  pull_request:
    paths:
      - 'k8s/**'         # only run chaos if K8s manifests changed
      - 'Dockerfile'
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
