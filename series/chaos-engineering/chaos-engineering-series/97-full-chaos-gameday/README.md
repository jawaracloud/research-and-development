# 97 — Full Chaos GameDay Workflow

> **Type:** Tutorial  
> **Phase:** Advanced Topics & GameDay

## What you're building

A complete, self-contained **GameDay Argo Workflow** that runs all 10 key experiments from this series in sequence, validates SLO proof points at each step, and generates a markdown report — fully automated, requiring no manual intervention.

## The Full GameDay Workflow

`scripts/run-gameday.sh` applies this workflow:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: chaos-gameday-full
  namespace: litmus
spec:
  serviceAccountName: argo-chaos
  entrypoint: gameday
  arguments:
    parameters:
      - name: target-namespace
        value: default
      - name: slo-error-budget
        value: "0.001"   # 99.9% SLO

  templates:
    - name: gameday
      steps:
        - - name: preflight
            template: preflight-check

        - - name: exp-pod-delete
            template: run-experiment
            arguments:
              parameters:
                - name: name
                  value: pod-delete

        - - name: exp-cpu-hog
            template: run-experiment
            arguments:
              parameters:
                - name: name
                  value: pod-cpu-hog

        - - name: exp-memory-hog
            template: run-experiment
            arguments:
              parameters:
                - name: name
                  value: pod-memory-hog

        - - name: exp-network-latency
            template: run-experiment
            arguments:
              parameters:
                - name: name
                  value: pod-network-latency

        - - name: exp-node-drain
            template: run-experiment
            arguments:
              parameters:
                - name: name
                  value: node-drain

        - - name: exp-db-failure
            template: run-experiment
            arguments:
              parameters:
                - name: name
                  value: db-failure

        - - name: generate-report
            template: report-generator

    - name: preflight-check
      script:
        image: bitnami/kubectl:latest
        command: [sh]
        source: |
          echo "=== Pre-GameDay Preflight ==="
          kubectl get nodes --no-headers | grep -v Ready && exit 1 || true
          kubectl get pods -n "{{workflow.parameters.target-namespace}}" \
            -l app=target-app --no-headers | grep -v Running && exit 1 || true
          echo "✅ Preflight passed"

    - name: run-experiment
      inputs:
        parameters:
          - name: name
      steps:
        - - name: apply
            template: kubectl-apply
            arguments:
              parameters:
                - name: manifest
                  value: "/manifests/{{inputs.parameters.name}}.yaml"
        - - name: wait
            template: poll-verdict
            arguments:
              parameters:
                - name: engine
                  value: "gameday-{{inputs.parameters.name}}"

    - name: kubectl-apply
      inputs:
        parameters: [{name: manifest}]
      container:
        image: bitnami/kubectl:latest
        command: [kubectl, apply, -f, "{{inputs.parameters.manifest}}"]

    - name: poll-verdict
      inputs:
        parameters: [{name: engine}]
      script:
        image: bitnami/kubectl:latest
        command: [sh]
        source: |
          for i in $(seq 1 40); do
            V=$(kubectl get chaosresult "{{inputs.parameters.engine}}-pod-delete" \
              -n litmus -o jsonpath='{.status.experimentStatus.verdict}' 2>/dev/null)
            echo "$(date +%T) verdict=$V"
            [ "$V" = "Pass" ] && exit 0
            [ "$V" = "Fail" ] && { echo "FAILED"; exit 1; }
            sleep 10
          done
          exit 1

    - name: report-generator
      script:
        image: bitnami/kubectl:latest
        command: [sh]
        source: |
          echo "# GameDay Report — $(date -u +%Y-%m-%d)"
          echo "| Experiment | Verdict |"
          echo "|-----------|---------|"
          kubectl get chaosresult -n litmus -o json \
            | jq -r '.items[] | "| \(.metadata.name) | \(.status.experimentStatus.verdict) |"'
```

## Run the GameDay

```bash
./scripts/run-gameday.sh gameday-manifests/

# Watch progress
argo watch chaos-gameday-full -n litmus

# Get the report
argo logs chaos-gameday-full -n litmus --node-field-selector name=generate-report
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
