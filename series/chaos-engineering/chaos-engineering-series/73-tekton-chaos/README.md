# 73 — Tekton Chaos

> **Type:** How-To  
> **Phase:** Observability & Automation

## Overview

Integrate chaos experiments as a Tekton `Task` and `Pipeline` step — the Kubernetes-native CI/CD approach for teams running Tekton for their GitOps workflows.

## Step 1: Install Tekton Pipelines

```bash
kubectl apply -f \
  https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

kubectl get pods -n tekton-pipelines
```

## Step 2: ChaosExperiment Task

`tekton/chaos-task.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: run-chaos-experiment
  namespace: default
spec:
  params:
    - name: engine-name
      type: string
    - name: chaos-namespace
      type: string
      default: litmus
    - name: timeout-seconds
      type: string
      default: "300"
  steps:
    - name: apply-engine
      image: bitnami/kubectl:latest
      script: |
        #!/usr/bin/env sh
        kubectl apply -f /workspace/manifests/$(params.engine-name).yaml \
          -n $(params.chaos-namespace)

    - name: wait-for-result
      image: bitnami/kubectl:latest
      script: |
        #!/usr/bin/env sh
        set -e
        TIMEOUT=$(params.timeout-seconds)
        ELAPSED=0
        RESULT_NAME="$(params.engine-name)-pod-delete"

        while [ $ELAPSED -lt $TIMEOUT ]; do
          VERDICT=$(kubectl get chaosresult "$RESULT_NAME" \
            -n $(params.chaos-namespace) \
            -o jsonpath='{.status.experimentStatus.verdict}' 2>/dev/null || echo "Awaited")

          echo "$(date): $VERDICT"
          if [ "$VERDICT" = "Pass" ]; then exit 0; fi
          if [ "$VERDICT" = "Fail" ]; then
            echo "Experiment FAILED"
            exit 1
          fi
          sleep 10
          ELAPSED=$((ELAPSED + 10))
        done
        echo "Timeout waiting for chaos result"
        exit 1
```

## Step 3: Chaos Pipeline

`tekton/chaos-pipeline.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: chaos-slo-gate
spec:
  tasks:
    - name: verify-staging
      taskRef:
        name: kubectl-deploy
      params:
        - name: cmd
          value: "kubectl rollout status deployment/target-app"

    - name: run-chaos
      taskRef:
        name: run-chaos-experiment
      runAfter: [verify-staging]
      params:
        - name: engine-name
          value: first-pod-delete

    - name: slo-validation
      taskRef:
        name: k6-test
      runAfter: [run-chaos]

    - name: cleanup
      taskRef:
        name: kubectl-deploy
      runAfter: [slo-validation]
      params:
        - name: cmd
          value: "kubectl delete chaosengine first-pod-delete -n litmus --ignore-not-found"
```

## Step 4: Trigger a PipelineRun

```bash
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: chaos-gate-run-
spec:
  pipelineRef:
    name: chaos-slo-gate
EOF

tkn pipelinerun logs -f -L
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
