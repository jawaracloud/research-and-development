# Chaos Engineering Series

> **100 lessons** · **Go + YAML** · **LitmusChaos · Chaos Mesh · Toxiproxy · k6 · Prometheus · Grafana**

A comprehensive, hands-on series for learning Chaos Engineering from first principles through to production-grade continuous chaos automation.

---

## Overview

| | |
|-|-|
| **Total Lessons** | 100 |
| **Primary Language** | Go, YAML |
| **Chaos Tools** | LitmusChaos v3, Chaos Mesh v2, Toxiproxy |
| **Load Testing** | k6 |
| **Observability** | Prometheus, Grafana, Loki, Jaeger |
| **Automation** | Argo Workflows, GitHub Actions, Tekton, ArgoCD |
| **Cloud** | AWS, GCP (patterns) |

---

## Curriculum

### Phase 1 — Foundations (Lessons 01–20)

Theory, principles, and first experiments in a local kind cluster.

| # | Lesson | Type |
|---|--------|------|
| 01 | [What Is Chaos Engineering](./01-what-is-chaos-engineering/) | Explanation |
| 02 | [Chaos vs Testing](./02-chaos-vs-testing/) | Explanation |
| 03 | [Steady-State Hypothesis](./03-steady-state-hypothesis/) | Explanation |
| 04 | [Blast Radius](./04-blast-radius/) | Explanation |
| 05 | [Chaos Maturity Model](./05-chaos-maturity-model/) | Explanation |
| 06 | [Chaos Tooling Landscape](./06-chaos-tooling-landscape/) | Reference |
| 07 | [Local Chaos Lab Setup](./07-local-chaos-lab-setup/) | Tutorial |
| 08 | [Target Application](./08-target-application/) | Tutorial |
| 09 | [Observability Foundation](./09-observability-foundation/) | Tutorial |
| 10 | [Chaos Experiment Anatomy](./10-chaos-experiment-anatomy/) | Explanation |
| 11 | [First Pod Delete](./11-first-pod-delete/) | Tutorial |
| 12 | [Probes and Validation](./12-probes-and-validation/) | How-To |
| 13 | [Chaos RBAC](./13-chaos-rbac/) | How-To |
| 14 | [Blast Radius Limiting](./14-blast-radius-limiting/) | How-To |
| 15 | [Chaos Schedules](./15-chaos-schedules/) | How-To |
| 16 | [Chaos Results](./16-chaos-results/) | Reference |
| 17 | [Annotation Check](./17-annotationcheck/) | How-To |
| 18 | [ChaosHub](./18-chaos-hub/) | Reference |
| 19 | [Chaos Workflow Introduction](./19-chaos-workflow-intro/) | Tutorial |
| 20 | [The Chaos Observability Loop](./20-chaos-observability-loop/) | Explanation |

---

### Phase 2 — Kubernetes Chaos (Lessons 21–40)

Pod, node, and control-plane fault injection.

| # | Lesson | Type |
|---|--------|------|
| 21 | [Pod CPU Hog](./21-pod-cpu-hog/) | Tutorial |
| 22 | [Pod Memory Hog](./22-pod-memory-hog/) | Tutorial |
| 23 | [Pod Network Latency](./23-pod-network-latency/) | Tutorial |
| 24 | [Pod Network Loss](./24-pod-network-loss/) | Tutorial |
| 25 | [Pod Network Corruption](./25-pod-network-corruption/) | Tutorial |
| 26 | [Pod Network Duplication](./26-pod-network-duplication/) | Tutorial |
| 27 | [Container Kill](./27-container-kill/) | Tutorial |
| 28 | [Node CPU Hog](./28-node-cpu-hog/) | Tutorial |
| 29 | [Node Memory Hog](./29-node-memory-hog/) | Tutorial |
| 30 | [Node Drain](./30-node-drain/) | Tutorial |
| 31 | [Node Taint](./31-node-taint/) | Tutorial |
| 32 | [Node Restart](./32-node-restart/) | Tutorial |
| 33 | [Node I/O Stress](./33-node-io-stress/) | Tutorial |
| 34 | [K8s API Server Chaos](./34-k8s-api-server-chaos/) | How-To |
| 35 | [etcd Disk Fill](./35-etcd-disk-fill/) | How-To |
| 36 | [CoreDNS Chaos](./36-coredns-chaos/) | Tutorial |
| 37 | [kube-proxy Chaos](./37-kube-proxy-chaos/) | Tutorial |
| 38 | [PVC Deletion](./38-pvc-deletion/) | Tutorial |
| 39 | [Deployment Scale Chaos](./39-deployment-scale-chaos/) | How-To |
| 40 | [HPA Chaos](./40-hpa-chaos/) | How-To |

---

### Phase 3 — Application & Network Chaos (Lessons 41–60)

Chaos Mesh, Toxiproxy, service meshes, and resilience patterns.

| # | Lesson | Type |
|---|--------|------|
| 41 | [Chaos Mesh Introduction](./41-chaos-mesh-intro/) | Tutorial |
| 42 | [Chaos Mesh PodChaos](./42-chaos-mesh-pod-chaos/) | Tutorial |
| 43 | [Chaos Mesh Network Partition](./43-chaos-mesh-network-partition/) | Tutorial |
| 44 | [Chaos Mesh Time Skew](./44-chaos-mesh-time-skew/) | Tutorial |
| 45 | [Chaos Mesh JVM Chaos](./45-chaos-mesh-jvm-chaos/) | Tutorial |
| 46 | [Chaos Mesh HTTP Chaos](./46-chaos-mesh-http-chaos/) | Tutorial |
| 47 | [Toxiproxy Introduction](./47-toxiproxy-intro/) | Tutorial |
| 48 | [Toxiproxy Latency](./48-toxiproxy-latency/) | Tutorial |
| 49 | [Toxiproxy Timeout](./49-toxiproxy-timeout/) | Tutorial |
| 50 | [Toxiproxy Bandwidth](./50-toxiproxy-bandwidth/) | Tutorial |
| 51 | [Circuit Breaker Validation](./51-circuit-breaker-validation/) | How-To |
| 52 | [Retry Validation](./52-retry-validation/) | How-To |
| 53 | [Timeout Budget](./53-timeout-budget/) | How-To |
| 54 | [Bulkhead Pattern](./54-bulkhead-pattern/) | How-To |
| 55 | [Fallback Validation](./55-fallback-validation/) | How-To |
| 56 | [Service Mesh Chaos (Istio)](./56-service-mesh-chaos/) | How-To |
| 57 | [Ingress Chaos](./57-ingress-chaos/) | Tutorial |
| 58 | [DNS Chaos](./58-dns-chaos/) | Tutorial |
| 59 | [TLS Certificate Expiry](./59-tls-cert-expiry/) | How-To |
| 60 | [Database Failure](./60-db-failure/) | Tutorial |

---

### Phase 4 — Observability & Automation (Lessons 61–80)

Metrics, dashboards, alerts, CI/CD pipelines, and GitOps.

| # | Lesson | Type |
|---|--------|------|
| 61 | [Prometheus Chaos Metrics](./61-prometheus-chaos-metrics/) | Tutorial |
| 62 | [Grafana Chaos Dashboard](./62-grafana-chaos-dashboard/) | Tutorial |
| 63 | [Alertmanager Chaos Alerts](./63-alertmanager-chaos-alerts/) | How-To |
| 64 | [SLO Burn Rate](./64-slo-burn-rate/) | How-To |
| 65 | [Loki Chaos Logs](./65-loki-chaos-logs/) | Tutorial |
| 66 | [Jaeger Tracing During Chaos](./66-jaeger-tracing-chaos/) | Tutorial |
| 67 | [k6 Load During Chaos](./67-k6-load-during-chaos/) | Tutorial |
| 68 | [k6 Thresholds as Hypothesis Gates](./68-k6-thresholds/) | How-To |
| 69 | [OpenTelemetry Chaos Observability](./69-opentelemetry-chaos/) | Tutorial |
| 70 | [Chaos Event Exporter](./70-chaos-event-exporter/) | Tutorial |
| 71 | [Argo Workflows Chaos](./71-argo-workflows-chaos/) | Tutorial |
| 72 | [GitHub Actions Chaos](./72-github-actions-chaos/) | How-To |
| 73 | [Tekton Chaos](./73-tekton-chaos/) | How-To |
| 74 | [GitOps Chaos](./74-gitops-chaos/) | How-To |
| 75 | [Chaos as Code](./75-chaos-as-code/) | Explanation |
| 76 | [Chaos Runbooks](./76-chaos-runbooks/) | Reference |
| 77 | [Chaos Reports](./77-chaos-reports/) | How-To |
| 78 | [Continuous Chaos](./78-continuous-chaos/) | How-To |
| 79 | [ChaosCenter](./79-chaoscenter/) | Tutorial |
| 80 | [Chaos Metrics API](./80-chaos-metrics-api/) | Reference |

---

### Phase 5 — Advanced Topics & GameDay (Lessons 81–100)

Cloud providers, stateful workloads, and running full GameDays.

| # | Lesson | Type |
|---|--------|------|
| 81 | [AWS EC2 Stop](./81-aws-ec2-stop/) | Tutorial |
| 82 | [AWS RDS Failure](./82-aws-rds-failure/) | Tutorial |
| 83 | [GCP VM Stop](./83-gcp-vm-stop/) | Tutorial |
| 84 | [Multi-Cluster Chaos](./84-multi-cluster-chaos/) | Tutorial |
| 85 | [Stateful Chaos](./85-stateful-chaos/) | Tutorial |
| 86 | [Chaos for Microservices](./86-chaos-for-microservices/) | How-To |
| 87 | [Chaos for Data Pipelines](./87-chaos-for-data-pipelines/) | Tutorial |
| 88 | [Chaos for Batch Jobs](./88-chaos-for-batch-jobs/) | Tutorial |
| 89 | [Security Chaos](./89-security-chaos/) | How-To |
| 90 | [Chaos for Serverless](./90-chaos-for-serverless/) | How-To |
| 91 | [GameDay Planning](./91-gameday-planning/) | How-To |
| 92 | [GameDay Execution](./92-gameday-execution/) | Tutorial |
| 93 | [Post-GameDay Analysis](./93-post-gameday-analysis/) | How-To |
| 94 | [Advanced Go Chaos Tests](./94-advanced-go-chaos-tests/) | Tutorial |
| 95 | [Chaos Engineering Culture](./95-chaos-culture/) | Explanation |
| 96 | [Chaos Maturity Assessment](./96-chaos-maturity-assessment/) | How-To |
| 97 | [Full Chaos GameDay Workflow](./97-full-chaos-gameday/) | Tutorial |
| 98 | [Resilience Scoring](./98-resilience-scoring/) | How-To |
| 99 | [Chaos in Production](./99-chaos-in-production/) | How-To |
| 100 | [What's Next](./100-whats-next/) | Reference |

---

## Quick Start

```bash
# 1. Verify tools
./scripts/verify-env.sh

# 2. Start local lab
docker compose up -d

# 3. Create kind cluster + install chaos tools
./scripts/setup-cluster.sh

# 4. Deploy target app
kubectl apply -f target-app/k8s/

# 5. Run your first experiment (Lesson 11)
kubectl apply -f 11-first-pod-delete/pod-delete-engine.yaml
kubectl get chaosresult -n litmus
```

---

## Directory Structure

```
chaos-engineering-series/
├── README.md               ← This file
├── go.mod                  ← Go module
├── docker-compose.yml      ← Local chaos lab
├── .devcontainer/          ← Dev Container config
├── scripts/
│   ├── setup-cluster.sh    ← Create kind cluster + install tools
│   ├── teardown.sh         ← Destroy cluster
│   ├── run-gameday.sh      ← Execute GameDay workflow
│   └── verify-env.sh       ← Check required tools
├── target-app/             ← Sample Go HTTP application
├── observability/          ← Prometheus / Grafana configs
└── NN-lesson-slug/
    └── README.md           ← Lesson (Diátaxis format)
```

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

---

*Part of the [Jawaracloud Research & Development](https://github.com/jawaracloud/research-and-development) mono-repository.*
