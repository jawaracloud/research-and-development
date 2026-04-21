# 71 — Argo Workflows Chaos

> **Type:** Tutorial  
> **Phase:** Observability & Automation

## What you're building

Embed chaos experiments as steps in an Argo Workflow DAG — executing infrastructure checks, load tests, chaos injection, and SLO validation as a fully automated, version-controlled pipeline.

## Architecture

```
Argo Workflow DAG
├── step: verify-infra          (kubectl checks)
├── step: start-load-test       (k6 background job)
├── step: inject-chaos          (apply ChaosEngine)
├── step: wait-for-result       (poll ChaosResult)
├── step: validate-slo          (query Prometheus)
└── step: cleanup               (delete ChaosEngine)
```

## Step 1: Full chaos workflow

`chaos-argo-workflow.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: chaos-slo-gate
  namespace: litmus
spec:
  serviceAccountName: argo-chaos
  entrypoint: pipeline
  templates:

    - name: pipeline
      dag:
        tasks:
          - name: verify-infra
            template: kubectl-check
            arguments:
              parameters:
                - name: cmd
                  value: "kubectl get pods -n default -l app=target-app --field-selector=status.phase=Running"

          - name: inject-chaos
            template: apply-manifest
            dependencies: [verify-infra]
            arguments:
              parameters:
                - name: manifest
                  value: "/manifests/pod-delete-engine.yaml"

          - name: wait-result
            template: poll-result
            dependencies: [inject-chaos]
            arguments:
              parameters:
                - name: engine
                  value: "first-pod-delete"

          - name: slo-check
            template: prometheus-check
            dependencies: [wait-result]

    - name: kubectl-check
      inputs:
        parameters: [{name: cmd}]
      container:
        image: bitnami/kubectl:latest
        command: [sh, -c]
        args: ["{{inputs.parameters.cmd}}"]

    - name: apply-manifest
      inputs:
        parameters: [{name: manifest}]
      container:
        image: bitnami/kubectl:latest
        command: [kubectl, apply, -f]
        args: ["{{inputs.parameters.manifest}}"]

    - name: poll-result
      inputs:
        parameters: [{name: engine}]
      script:
        image: bitnami/kubectl:latest
        command: [sh]
        source: |
          for i in $(seq 1 30); do
            VERDICT=$(kubectl get chaosresult \
              {{inputs.parameters.engine}}-pod-delete \
              -n litmus -o jsonpath='{.status.experimentStatus.verdict}' 2>/dev/null)
            echo "Attempt $i: $VERDICT"
            [ "$VERDICT" = "Pass" ] && exit 0
            [ "$VERDICT" = "Fail" ] && exit 1
            sleep 10
          done
          exit 1

    - name: prometheus-check
      script:
        image: alpine/curl:latest
        command: [sh]
        source: |
          RATE=$(curl -s "http://prometheus.monitoring:9090/api/v1/query" \
            --data-urlencode 'query=sum(rate(http_requests_total{status=~"5.."}[5m]))/sum(rate(http_requests_total[5m]))' \
            | jq -r '.data.result[0].value[1]')
          echo "Error rate: $RATE"
          [ $(echo "$RATE < 0.01" | bc -l) -eq 1 ] && exit 0 || exit 1
```

## Step 2: Run

```bash
argo submit --watch chaos-argo-workflow.yaml -n litmus
argo logs chaos-slo-gate -n litmus
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
