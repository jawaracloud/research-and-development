# 45 — Chaos Mesh JVM Chaos

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Use Chaos Mesh's `JVMChaos` to inject faults directly into JVM-based applications (Java, Kotlin, Scala), testing exception handling, retry logic, and observability for specific code paths.

> **Note:** This lesson targets JVM applications. If your stack is Go or Rust, skim the concepts — they apply conceptually to application-layer fault injection even if the tooling differs.

## JVMChaos Actions

| Action | Description |
|--------|-------------|
| `exception` | Throw a specified exception from a method |
| `return` | Override a method's return value |
| `delay` | Add latency to a specific method call |
| `stress` | CPU/memory stress on JVM heap |
| `gc` | Trigger garbage collection |

## Step 1: JVMChaos — inject exception on database call

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: JVMChaos
metadata:
  name: db-exception
  namespace: default
spec:
  action: exception
  mode: all
  selector:
    namespaces: [default]
    labelSelectors:
      app: java-service
  exception: "java.sql.SQLException: simulated DB error"
  class: "com.example.repository.UserRepository"
  method: "findById"
  duration: "60s"
```

## Step 2: JVMChaos — add latency to a specific method

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: JVMChaos
metadata:
  name: method-latency
  namespace: default
spec:
  action: delay
  mode: all
  selector:
    namespaces: [default]
    labelSelectors:
      app: java-service
  class: "com.example.service.PaymentService"
  method: "processPayment"
  latency: 2000      # 2000 ms delay
  duration: "60s"
```

## Step 3: JVMChaos — override return value

```yaml
spec:
  action: return
  returnValue: "null"     # or a JSON payload
  class: "com.example.cache.CacheService"
  method: "get"
```

## Equivalent pattern for Go (no JVM chaos needed)

In Go, use interface mocking or build tags to inject faults at test time:

```go
// Dependency injection allows fault injection in tests
type DBAdapter interface {
    FindByID(ctx context.Context, id int) (*User, error)
}

type FaultyDB struct{}
func (f *FaultyDB) FindByID(ctx context.Context, id int) (*User, error) {
    return nil, errors.New("simulated DB error")
}
```

## Insights this experiment reveals

- Are exceptions from the DB layer propagated correctly to the HTTP response?
- Does the application log structured errors with context (user ID, request ID)?
- Is there retry logic for transient `SQLException`s?

---
*Part of the 100-Lesson Chaos Engineering Series.*
