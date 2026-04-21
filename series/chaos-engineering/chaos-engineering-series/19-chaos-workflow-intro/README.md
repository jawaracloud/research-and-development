# 19 — Chaos Workflow Introduction

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

A **multi-step chaos workflow** that sequentially:
1. Deletes a pod
2. Injects network latency
3. Stress CPU

LitmusChaos v3 uses **Argo Workflows** under the hood to orchestrate multi-step experiments.

## Why Workflows?

Single ChaosEngines are isolated experiments. Workflows let you:
- Chain multiple experiments (serial or parallel)
- Share data between steps
- Add human-approval gates
- Export to CI/CD

## Step 1: Install Argo Workflows (if not already)

```bash
kubectl create namespace argo
kubectl apply -n argo \
  -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.0/install.yaml
```

## Step 2: Define the Workflow

`multi-step-workflow.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: chaos-multi-step
  namespace: litmus
spec:
  serviceAccountName: argo-chaos
  entrypoint: chaos-pipeline
  templates:
    - name: chaos-pipeline
      steps:
        - - name: step-pod-delete
            template: run-pod-delete
        - - name: step-network-latency
            template: run-network-latency
        - - name: step-cpu-hog
            template: run-cpu-hog

    - name: run-pod-delete
      inputs:
        artifacts:
          - name: engine
            path: /tmp/engine.yaml
            raw:
              data: |
                apiVersion: litmuschaos.io/v1alpha1
                kind: ChaosEngine
                metadata:
                  name: workflow-pod-delete
                  namespace: litmus
                spec:
                  appinfo:
                    appns: default
                    applabel: "app=target-app"
                    appkind: deployment
                  chaosServiceAccount: litmus-admin
                  experiments:
                    - name: pod-delete
                      spec:
                        components:
                          env:
                            - name: TOTAL_CHAOS_DURATION
                              value: "20"
      container:
        image: litmuschaos/k8s:latest
        command: [sh, -c]
        args:
          - kubectl apply -f /tmp/engine.yaml && sleep 30 &&
            kubectl get chaosresult workflow-pod-delete-pod-delete -n litmus
            -o jsonpath='{.status.experimentStatus.verdict}'

    - name: run-network-latency
      container:
        image: litmuschaos/k8s:latest
        command: [sh, -c]
        args: ["echo 'Running network latency step'"]

    - name: run-cpu-hog
      container:
        image: litmuschaos/k8s:latest
        command: [sh, -c]
        args: ["echo 'Running CPU hog step'"]
```

## Step 3: Apply and Watch

```bash
kubectl apply -f multi-step-workflow.yaml

# Watch progress
kubectl get workflow -n litmus -w

# Or use Argo CLI
argo watch chaos-multi-step -n litmus
```

## Step 4: View Results

```bash
argo get chaos-multi-step -n litmus
# Shows step-by-step status

kubectl get chaosresult -n litmus
```

## Serial vs. Parallel Steps

```yaml
# Serial (default) — wait for previous step
steps:
  - - name: step-1
      template: my-template
  - - name: step-2
      template: my-template

# Parallel — both run simultaneously
steps:
  - - name: step-1
      template: my-template
    - name: step-2
      template: other-template
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
