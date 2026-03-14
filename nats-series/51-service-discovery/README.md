# 51 — Service Discovery with NATS

> **Type:** Tutorial  
> **Phase:** Patterns & Architecture

## What you're building

Use NATS subjects as a service registry — services announce their presence via heartbeats and clients discover them dynamically without external registries (Consul, etcd).

## Pattern: Subject-Based Discovery

```
Service: subscribe to "svc.users.get" → it's available
Client:  nc.Request("svc.users.get", payload, timeout) → routed to available service

New service instance → subscribe to same subject (queue group)
→ automatic load balancing, no registry update needed
```

## Step 1: Service Registration via Heartbeat

```go
func registerService(nc *nats.Conn, name, version, addr string) {
    info := map[string]string{
        "name": name, "version": version, "addr": addr,
        "ts": time.Now().UTC().Format(time.RFC3339),
    }

    // Announce presence every 5 seconds
    ticker := time.NewTicker(5 * time.Second)
    for range ticker.C {
        data, _ := json.Marshal(info)
        nc.Publish("_registry."+name, data)
    }
}

// users-service/main.go
go registerService(nc, "users-svc", "v2.1.0", "users-svc:8080")
```

## Step 2: Service Directory

```go
type ServiceDirectory struct {
    mu       sync.RWMutex
    services map[string]ServiceInfo
}

type ServiceInfo struct {
    Name    string
    Version string
    LastSeen time.Time
}

func (sd *ServiceDirectory) Watch(nc *nats.Conn) {
    nc.Subscribe("_registry.>", func(msg *nats.Msg) {
        var info ServiceInfo
        json.Unmarshal(msg.Data, &info)
        info.LastSeen = time.Now()

        sd.mu.Lock()
        sd.services[info.Name] = info
        sd.mu.Unlock()
    })

    // Prune stale services (not seen in 15s)
    go func() {
        for range time.NewTicker(10 * time.Second).C {
            sd.mu.Lock()
            for name, svc := range sd.services {
                if time.Since(svc.LastSeen) > 15*time.Second {
                    delete(sd.services, name)
                    log.Printf("Service %s deregistered (timeout)", name)
                }
            }
            sd.mu.Unlock()
        }
    }()
}
```

## Step 3: NATS Micro Framework (built-in service discovery)

NATS 2.10 includes a built-in Micro Services framework:

```go
import "github.com/nats-io/nats.go/micro"

svc, err := micro.AddService(nc, micro.Config{
    Name:        "users-svc",
    Version:     "2.1.0",
    Description: "User management service",
})

svc.AddEndpoint("get", micro.HandlerFunc(func(req micro.Request) {
    var queryReq GetUserRequest
    json.Unmarshal(req.Data(), &queryReq)
    user := getUser(queryReq.ID)
    req.Respond(mustJSON(user))
}))

// Discovery:
// nats micro ls
// nats micro info users-svc
// nats micro ping users-svc
```

---
*Part of the 100-Lesson NATS Series.*
