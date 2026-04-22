# 70 — Chaos Event Exporter

> **Type:** Tutorial  
> **Phase:** Observability & Automation

## What you're building

A Go microservice that watches LitmusChaos `ChaosResult` Kubernetes events and forwards them to Slack, a webhook, or a custom event bus — giving your team real-time visibility into chaos experiment outcomes.

## Step 1: Go event exporter

`main.go`:

```go
package main

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "time"

    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/client-go/dynamic"
    "k8s.io/client-go/tools/clientcmd"
)

type SlackPayload struct {
    Text string `json:"text"`
}

func main() {
    cfg, _ := clientcmd.BuildConfigFromFlags("", os.Getenv("KUBECONFIG"))
    dyn, _ := dynamic.NewForConfig(cfg)
    webhook := os.Getenv("SLACK_WEBHOOK_URL")

    gvr := schema.GroupVersionResource{
        Group:    "litmuschaos.io",
        Version:  "v1alpha1",
        Resource: "chaosresults",
    }

    seen := map[string]string{} // name → last phase
    ticker := time.NewTicker(10 * time.Second)
    for range ticker.C {
        list, err := dyn.Resource(gvr).Namespace("litmus").
            List(context.Background(), metav1.ListOptions{})
        if err != nil {
            log.Println("list error:", err)
            continue
        }
        for _, item := range list.Items {
            name := item.GetName()
            phase, _, _ := unstructured.NestedString(item.Object,
                "status", "experimentStatus", "phase")
            verdict, _, _ := unstructured.NestedString(item.Object,
                "status", "experimentStatus", "verdict")

            if prev, ok := seen[name]; ok && prev == phase {
                continue // no change
            }
            seen[name] = phase

            if phase == "Completed" {
                emoji := "✅"
                if verdict != "Pass" {
                    emoji = "❌"
                }
                msg := fmt.Sprintf("%s ChaosResult *%s*: `%s`", emoji, name, verdict)
                notify(webhook, msg)
            }
        }
    }
}

func notify(webhookURL, msg string) {
    payload, _ := json.Marshal(SlackPayload{Text: msg})
    http.Post(webhookURL, "application/json", bytes.NewBuffer(payload))
}
```

## Step 2: Deploy as a Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chaos-event-exporter
  namespace: litmus
spec:
  replicas: 1
  template:
    spec:
      serviceAccountName: litmus-admin
      containers:
        - name: exporter
          image: golang:1.23-alpine
          env:
            - name: SLACK_WEBHOOK_URL
              valueFrom:
                secretKeyRef:
                  name: chaos-slack-secret
                  key: webhook-url
```

## Step 3: Test the exporter

```bash
# Run a chaos experiment
kubectl apply -f ../11-first-pod-delete/pod-delete-engine.yaml

# Watch Slack — you should receive:
# ✅ ChaosResult first-pod-delete-pod-delete: `Pass`
```

## Sample Slack message format

```
✅ ChaosResult *first-pod-delete-pod-delete*: `Pass`
   Engine: first-pod-delete
   Duration: 30s
   Probes: health-endpoint → Passed
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
