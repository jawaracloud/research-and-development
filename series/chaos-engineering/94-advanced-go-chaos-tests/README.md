# 94 — Advanced Go Chaos Tests

> **Type:** Tutorial  
> **Phase:** Advanced Topics & GameDay

## What you're building

Write Go integration tests that automate the chaos → observe → validate cycle using the Kubernetes client-go library and a Prometheus API client — transforming chaos experiments into runnable `go test` cases.

## Step 1: Test infrastructure helper

`chaos_test.go`:

```go
package chaos_test

import (
    "context"
    "os"
    "os/exec"
    "testing"
    "time"

    "k8s.io/client-go/dynamic"
    "k8s.io/client-go/tools/clientcmd"
)

func newDynamicClient(t *testing.T) dynamic.Interface {
    t.Helper()
    cfg, err := clientcmd.BuildConfigFromFlags(
        "", os.Getenv("KUBECONFIG"))
    if err != nil {
        t.Fatalf("kubeconfig: %v", err)
    }
    dyn, err := dynamic.NewForConfig(cfg)
    if err != nil {
        t.Fatalf("dynamic client: %v", err)
    }
    return dyn
}

func applyChaosEngine(t *testing.T, manifest string) {
    t.Helper()
    cmd := exec.Command("kubectl", "apply", "-f", manifest)
    if out, err := cmd.CombinedOutput(); err != nil {
        t.Fatalf("apply chaos engine: %v\n%s", err, out)
    }
}

func deleteChaosEngine(t *testing.T, name, ns string) {
    t.Helper()
    exec.Command("kubectl", "delete", "chaosengine", name, "-n", ns,
        "--ignore-not-found").Run()
}

func waitForChaosResult(t *testing.T, engine, ns string, timeout time.Duration) string {
    t.Helper()
    deadline := time.Now().Add(timeout)
    for time.Now().Before(deadline) {
        out, _ := exec.Command("kubectl", "get", "chaosresult",
            engine+"-pod-delete", "-n", ns,
            "-o", "jsonpath={.status.experimentStatus.verdict}").Output()
        verdict := string(out)
        if verdict == "Pass" || verdict == "Fail" {
            return verdict
        }
        time.Sleep(5 * time.Second)
    }
    t.Fatalf("chaos result timeout after %v", timeout)
    return ""
}
```

## Step 2: Hypothesis test

```go
func TestPodDeleteHypothesis(t *testing.T) {
    const (
        manifest  = "chaos-engineering-series/11-first-pod-delete/pod-delete-engine.yaml"
        engine    = "first-pod-delete"
        namespace = "litmus"
    )

    // Pre-chaos: assert baseline health
    t.Log("Asserting pre-chaos baseline")
    assertHttpOK(t, "http://localhost:8080/health", 5*time.Second)

    // Inject chaos
    t.Log("Applying chaos engine")
    applyChaosEngine(t, manifest)
    t.Cleanup(func() { deleteChaosEngine(t, engine, namespace) })

    // Wait for result
    verdict := waitForChaosResult(t, engine, namespace, 3*time.Minute)
    t.Logf("Chaos result: %s", verdict)

    if verdict != "Pass" {
        t.Errorf("Chaos experiment FAILED: hypothesis not satisfied")
    }

    // Post-chaos: assert recovery
    time.Sleep(15 * time.Second)
    t.Log("Asserting post-chaos recovery")
    assertHttpOK(t, "http://localhost:8080/health", 30*time.Second)
}
```

## Step 3: Run as part of CI

```bash
go test -v -timeout 10m ./chaos/... -run TestPodDeleteHypothesis
```

Control with build tags:

```go
//go:build chaos
// +build chaos
```

```bash
go test -tags chaos ./chaos/... -v
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
