# 79 — Chaos Dashboard with ChaosCenter

> **Type:** Tutorial  
> **Phase:** Observability & Automation

## What you're building

Deploy and configure **ChaosCenter** — LitmusChaos's full-stack governance platform — to manage experiments, teams, schedules, and results through a web UI.

## What ChaosCenter provides

- Web UI for creating and managing ChaosEngines
- Multi-team workspace with RBAC
- Chaos workflow scheduling
- Analytics: pass/fail history, experiment timeline
- ChaosHub management
- Resilience score per application

## Step 1: Install ChaosCenter

```bash
kubectl apply -f \
  https://raw.githubusercontent.com/litmuschaos/litmus/3.9.0/mkdocs/docs/3.9.0/litmus-getting-started.yaml

# Wait for all pods
kubectl get pods -n litmus -w
# All should be Running: litmusportal-frontend, litmusportal-server, mongo

# Port-forward the frontend
kubectl port-forward svc/litmusportal-frontend 9091:9091 -n litmus
```

## Step 2: Initial login

```
URL:      http://localhost:9091
Username: admin
Password: litmus  (change on first login!)
```

## Step 3: Connect your agent

ChaosCenter uses a **chaos delegate** (agent) that connects the cluster to ChaosCenter:

```bash
# Install litmusctl
curl -L -o litmusctl \
  https://github.com/litmuschaos/litmusctl/releases/download/v0.24.0/litmusctl-linux-amd64
chmod +x litmusctl
mv litmusctl /usr/local/bin/

# Login
litmusctl config set-account --endpoint http://localhost:9091 \
  --username admin --password litmus

# Connect cluster as delegate
litmusctl create delegate \
  --name "chaos-lab" \
  --project-id $(litmusctl get projects -o json | jq -r '.[0].ID')
```

## Step 4: Key ChaosCenter features to explore

### Resilience Probes (reusable)
Create shared HTTP/Prometheus probes and reference them across multiple ChaosEngines.

### Teams & RBAC
```
Workspaces → Project Settings → Invite Members
Roles: Owner, Editor, Viewer
```

### Analytics Dashboard
View:
- Experiment pass rate over time
- Resilience score (0–100) per workload
- Failure frequency heatmap

### Chaos Hubs
Connect private Git repo as a custom ChaosHub to share internal experiments.

## Resilience Score Formula

```
Score = (Passed Experiments / Total Experiments) × 100
```

Target: **> 85** for production workloads.

---
*Part of the 100-Lesson Chaos Engineering Series.*
