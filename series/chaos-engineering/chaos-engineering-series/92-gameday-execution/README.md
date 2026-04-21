# 92 — GameDay Execution

> **Type:** Tutorial  
> **Phase:** Advanced Topics & GameDay

## What you're building

Execute a complete GameDay against the local chaos lab, running 3 experiments in sequence with full observability, real load, and documented findings.

## Pre-GameDay setup

```bash
# 1. Start all lab services
docker compose up -d

# 2. Set up cluster and install chaos tools
./scripts/setup-cluster.sh

# 3. Deploy target-app
kubectl apply -f target-app/k8s/

# 4. Start k6 background load (runs throughout GameDay)
k6 run chaos-engineering-series/67-k6-load-during-chaos/load-test.js &
K6_PID=$!

# 5. Open dashboards
kubectl port-forward svc/kube-prom-grafana 3000:80 -n monitoring &
kubectl port-forward svc/jaeger-query 16686:16686 -n observability &
echo "Grafana: http://localhost:3000"
echo "Jaeger:  http://localhost:16686"
```

## Experiment 1: Pod Delete (09:45)

```bash
# Record start time
echo "E1 start: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Apply chaos
kubectl apply -f \
  chaos-engineering-series/11-first-pod-delete/pod-delete-engine.yaml

# Watch (Journalist records observations)
kubectl get pods -n default -w
kubectl get chaosresult -n litmus -w

# Record result
echo "E1 end: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl describe chaosresult first-pod-delete-pod-delete -n litmus
```

## Experiment 2: Node Drain (10:15)

```bash
echo "E2 start: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl apply -f \
  chaos-engineering-series/30-node-drain/node-drain-engine.yaml

# Manual drain for more control
kubectl cordon chaos-lab-worker
kubectl drain chaos-lab-worker \
  --ignore-daemonsets --delete-emptydir-data --timeout=90s

# Watch rescheduling
kubectl get pods -n default -o wide -w

# Restore
kubectl uncordon chaos-lab-worker
echo "E2 end: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

## Experiment 3: Database Failure (11:00)

```bash
echo "E3 start: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl apply -f \
  chaos-engineering-series/60-db-failure/postgres-kill.yaml

# Watch app error handling
kubectl logs -l app=target-app -n default -f | grep -E "error|unavailable|reconnect"

echo "E3 end: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

## Stop load test and generate summary

```bash
# Stop k6
kill $K6_PID

# Print k6 summary was already logged

# Query pass rates
kubectl get chaosresult -n litmus \
  -o json | jq '.items[] | {name:.metadata.name, verdict:.status.experimentStatus.verdict}'
```

## Live Documentation Template

```markdown
# GameDay Log — [Date]

## 09:45 Experiment 1 — Pod Delete
- Trigger: kubectl apply pod-delete-engine.yaml
- Observation: Pod xyz deleted at 09:45:12; rescheduled at 09:45:34
- Error rate: 0.2% (22s spike)
- Hypothesis: PASS ✅

## 10:15 Experiment 2 — Node Drain
- ...
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
