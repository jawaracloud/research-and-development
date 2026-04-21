# Architecture Diagrams

## High-Level Architecture

### ASCII Diagram

```
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                        INTERNET                             │
                                    └─────────────────────────────────────────────────────────────┘
                                                              │
                                                              ▼
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                     LOAD BALANCER                           │
                                    │                   (nginx / cloud LB)                        │
                                    └─────────────────────────────────────────────────────────────┘
                                                              │
                         ┌────────────────────────────────────┼────────────────────────────────────┐
                         │                                    │                                    │
                         ▼                                    ▼                                    ▼
              ┌──────────────────────┐            ┌──────────────────────┐            ┌──────────────────────┐
              │                      │            │                      │            │                      │
              │    WAITING ROOM      │            │    WAITING ROOM      │            │    WAITING ROOM      │
              │      SERVER 1        │            │      SERVER 2        │            │      SERVER 3        │
              │                      │            │                      │            │                      │
              │  ┌────────────────┐  │            │  ┌────────────────┐  │            │  ┌────────────────┐  │
              │  │  HTTP Handler  │  │            │  │  HTTP Handler  │  │            │  │  HTTP Handler  │  │
              │  └───────┬────────┘  │            │  └───────┬────────┘  │            │  └───────┬────────┘  │
              │          │           │            │          │           │            │          │           │
              │  ┌───────▼────────┐  │            │  ┌───────▼────────┐  │            │  ┌───────▼────────┐  │
              │  │ Queue Service  │  │            │  │ Queue Service  │  │            │  │ Queue Service  │  │
              │  └───────┬────────┘  │            │  └───────┬────────┘  │            │  └───────┬────────┘  │
              │          │           │            │          │           │            │          │           │
              │  ┌───────▼────────┐  │            │  ┌───────▼────────┐  │            │  ┌───────▼────────┐  │
              │  │ Token Service  │  │            │  │ Token Service  │  │            │  │ Token Service  │  │
              │  └───────┬────────┘  │            │  └───────┬────────┘  │            │  └───────┬────────┘  │
              │          │           │            │          │           │            │          │           │
              │  ┌───────▼────────┐  │            │  ┌───────▼────────┐  │            │  ┌───────▼────────┐  │
              │  │ Heartbeat Svc  │  │            │  │ Heartbeat Svc  │  │            │  │ Heartbeat Svc  │  │
              │  └───────┬────────┘  │            │  └───────┬────────┘  │            │  └───────┬────────┘  │
              │          │           │            │          │           │            │          │           │
              └──────────┼───────────┘            └──────────┼───────────┘            └──────────┼───────────┘
                         │                                    │                                    │
                         └────────────────────────────────────┼────────────────────────────────────┘
                                                              │
                         ┌────────────────────────────────────┼────────────────────────────────────┐
                         │                                    │                                    │
                         ▼                                    ▼                                    ▼
              ┌──────────────────────┐            ┌──────────────────────┐            ┌──────────────────────┐
              │                      │            │                      │            │                      │
              │     DRAGONFLYDB      │            │        NATS          │            │     PROMETHEUS       │
              │    (Redis-compatible)│            │    (JetStream)       │            │     (Metrics)        │
              │                      │            │                      │            │                      │
              │  • Queue Lists       │            │  • Position Events   │            │  • Event counts      │
              │  • Position Hashes   │            │  • Session Events    │            │  • Latency histos    │
              │  • Session Data      │            │  • Queue Events      │            │  • Queue gauges      │
              │  • Heartbeat ZSET    │            │  • System Events     │            │  • Error rates       │
              │  • Rate Limiters     │            │  • DLQ               │            │                      │
              │                      │            │                      │            │                      │
              └──────────────────────┘            └──────────────────────┘            └──────────────────────┘
```

---

## User Flow Diagram

### Mermaid Flowchart

```mermaid
flowchart TD
    subgraph Client["Client (Browser)"]
        A[User Arrives] --> B{Has Valid Token?}
        B -->|No| C[Request Enqueue]
        B -->|Yes| D[Check Status]
    end
    
    subgraph API["Waiting Room API"]
        C --> E[Create Position]
        E --> F[Generate JWT Token]
        F --> G[Store in DragonFlyDB]
        G --> H[Return Token + Position]
        
        D --> I[Validate Token]
        I --> J{Position Status?}
        J -->|Waiting| K[Return Queue Position]
        J -->|Admitted| L[Return Session Token]
        J -->|Expired| M[Return Error]
        
        H --> N[Start Heartbeat Loop]
        N --> O[Send Heartbeat]
        O --> P{Still Waiting?}
        P -->|Yes| O
        P -->|No| Q[Redirect to Target]
    end
    
    subgraph Storage["Storage Layer"]
        G --> R[(DragonFlyDB)]
        O --> S[Update Heartbeat]
        S --> R
    end
    
    subgraph Events["Event System"]
        E --> T[Publish Enqueued Event]
        L --> U[Publish Admitted Event]
        T --> V[(NATS JetStream)]
        U --> V
    end
```

---

## Component Interaction Diagram

### Mermaid Sequence Diagram

```mermaid
sequenceDiagram
    participant C as Client
    participant LB as Load Balancer
    participant API as API Server
    participant QS as Queue Service
    participant TS as Token Service
    participant DF as DragonFlyDB
    participant NATS as NATS
    participant HB as Heartbeat Worker
    
    Note over C,HB: User Enrollment Flow
    C->>LB: POST /enqueue
    LB->>API: Route request
    API->>QS: Enqueue(queue_id, user_info)
    QS->>DF: LPUSH queue:waiting
    QS->>DF: ZADD positions
    QS->>DF: HSET position metadata
    DF-->>QS: OK
    QS->>TS: GenerateToken(position)
    TS-->>QS: JWT Token
    QS->>NATS: Publish position.enqueued
    QS-->>API: Position + Token
    API-->>C: 200 OK + Token + Position Info
    
    Note over C,HB: Heartbeat Flow
    loop Every 10 seconds
        C->>API: POST /heartbeat
        API->>QS: RecordHeartbeat(position_id)
        QS->>DF: HSET last_heartbeat
        QS->>DF: ZADD heartbeat:active
        DF-->>QS: OK
        QS-->>API: Position Info
        API-->>C: 200 OK + Updated Position
    end
    
    Note over C,HB: Admission Flow
    HB->>QS: AdmitNext(queue_id)
    QS->>DF: Check admission tokens
    DF-->>QS: Tokens available
    QS->>DF: RPOP queue:waiting
    DF-->>QS: position_id
    QS->>DF: ZREM positions
    QS->>TS: GenerateSessionToken(position)
    TS-->>QS: Session JWT
    QS->>NATS: Publish position.admitted
    QS-->>HB: Position + Session Token
    
    Note over C,HB: Cleanup Flow
    loop Every 5 seconds
        HB->>DF: ZRANGEBYSCORE heartbeat:active
        DF-->>HB: Expired positions
        loop For each expired
            HB->>DF: ZREM positions
            HB->>DF: HSET status=expired
            HB->>NATS: Publish position.expired
        end
    end
```

---

## Data Flow Diagram

### Mermaid Graph

```mermaid
graph TB
    subgraph Input["Input Sources"]
        U1[Web Browser]
        U2[Mobile App]
        U3[API Client]
    end
    
    subgraph Gateway["API Gateway"]
        LB[Load Balancer]
        RL[Rate Limiter]
        AUTH[Auth Middleware]
    end
    
    subgraph Services["Core Services"]
        ENQ[Enqueue Handler]
        STAT[Status Handler]
        HB[Heartbeat Handler]
        ADM[Admin Handler]
    end
    
    subgraph Business["Business Logic"]
        QS[Queue Service]
        SS[Session Service]
        TK[Token Service]
        AC[Admission Controller]
    end
    
    subgraph Storage["Data Layer"]
        DF[(DragonFlyDB)]
        NATS[(NATS JetStream)]
    end
    
    subgraph Output["Output"]
        EVT[Event Consumers]
        MET[Metrics Exporter]
        LOG[Log Aggregator]
    end
    
    U1 --> LB
    U2 --> LB
    U3 --> LB
    
    LB --> RL
    RL --> AUTH
    AUTH --> ENQ
    AUTH --> STAT
    AUTH --> HB
    AUTH --> ADM
    
    ENQ --> QS
    STAT --> QS
    HB --> QS
    ADM --> QS
    
    QS --> SS
    QS --> TK
    QS --> AC
    
    QS --> DF
    SS --> DF
    TK --> DF
    AC --> DF
    
    QS --> NATS
    SS --> NATS
    
    NATS --> EVT
    DF --> MET
    QS --> LOG
```

---

## Deployment Architecture

### Kubernetes Deployment

```yaml
# Simplified Kubernetes architecture
┌─────────────────────────────────────────────────────────────────────────────┐
│                              KUBERNETES CLUSTER                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                           INGRESS CONTROLLER                          │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┼───────────────────────────────────┐  │
│  │                     WAITING ROOM NAMESPACE                            │  │
│  │                                                                       │  │
│  │   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐      │  │
│  │   │  API POD 1      │  │  API POD 2      │  │  API POD 3      │      │  │
│  │   │  - chi router   │  │  - chi router   │  │  - chi router   │      │  │
│  │   │  - queue svc    │  │  - queue svc    │  │  - queue svc    │      │  │
│  │   │  - token svc    │  │  - token svc    │  │  - token svc    │      │  │
│  │   └────────┬────────┘  └────────┬────────┘  └────────┬────────┘      │  │
│  │            │                    │                    │                │  │
│  │            └────────────────────┼────────────────────┘                │  │
│  │                                 │                                     │  │
│  │   ┌─────────────────────────────┼─────────────────────────────────┐   │  │
│  │   │                     SERVICES │                                 │   │  │
│  │   │   ┌─────────────────┐  ┌─────▼─────────┐  ┌─────────────────┐ │   │  │
│  │   │   │ waitingroom-api │  │ dragonflydb   │  │ nats            │ │   │  │
│  │   │   │ (ClusterIP)      │  │ (ClusterIP)   │  │ (ClusterIP)     │ │   │  │
│  │   │   └─────────────────┘  └───────────────┘  └─────────────────┘ │   │  │
│  │   └───────────────────────────────────────────────────────────────┘   │  │
│  │                                                                       │  │
│  │   ┌───────────────────────────────────────────────────────────────┐   │  │
│  │   │                    STATEFUL SETS                               │   │  │
│  │   │   ┌─────────────────┐  ┌─────────────────┐                    │   │  │
│  │   │   │ dragonflydb-0   │  │ nats-0          │                    │   │  │
│  │   │   │ dragonflydb-1   │  │ nats-1          │                    │   │  │
│  │   │   │ dragonflydb-2   │  │ nats-2          │                    │   │  │
│  │   │   └─────────────────┘  └─────────────────┘                    │   │  │
│  │   └───────────────────────────────────────────────────────────────┘   │  │
│  │                                                                       │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                     MONITORING NAMESPACE                              │   │
│  │   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐      │   │
│  │   │ prometheus      │  │ grafana         │  │ alertmanager    │      │   │
│  │   └─────────────────┘  └─────────────────┘  └─────────────────┘      │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Request Flow Diagram

### ASCII Request Flow

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              REQUEST PROCESSING FLOW                                 │
└─────────────────────────────────────────────────────────────────────────────────────┘

    REQUEST                MIDDLEWARE                 HANDLER                 SERVICE
    ───────                ──────────                 ───────                 ───────

    ┌─────────┐
    │ HTTP    │
    │ Request │
    └────┬────┘
         │
         ▼
    ┌─────────────────────────────────────────────────────────────────────────────────┐
    │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │
    │  │   Logging   │───▶│    CORS     │───▶│ Rate Limit  │───▶│  Recovery   │       │
    │  │  (request   │    │  (headers)  │    │  (sliding   │    │  (panic     │       │
    │  │   ID, time) │    │             │    │   window)   │    │  recovery)  │       │
    │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘       │
    └─────────────────────────────────────────────────────────────────────────────────┘
                                                                              │
         ┌────────────────────────────────────────────────────────────────────┘
         │
         ▼
    ┌─────────────────────────────────────────────────────────────────────────────────┐
    │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │
    │  │    Auth     │───▶│ Validation  │───▶│   Handler   │───▶│   Service   │       │
    │  │  (JWT check)│    │  (request   │    │  (business  │    │  (domain    │       │
    │  │             │    │   schema)   │    │   logic)    │    │   logic)    │       │
    │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘       │
    └─────────────────────────────────────────────────────────────────────────────────┘
                                                                              │
         ┌────────────────────────────────────────────────────────────────────┘
         │
         ▼
    ┌─────────────────────────────────────────────────────────────────────────────────┐
    │                              STORAGE LAYER                                        │
    │  ┌─────────────────────────────────┐    ┌─────────────────────────────────┐      │
    │  │         DragonFlyDB             │    │            NATS                 │      │
    │  │  ┌───────────┐ ┌───────────┐   │    │  ┌───────────┐ ┌───────────┐   │      │
    │  │  │   Queue   │ │  Session  │   │    │  │  Publish  │ │  Consume  │   │      │
    │  │  │   Store   │ │   Store   │   │    │  │  Events   │ │  Events   │   │      │
    │  │  └───────────┘ └───────────┘   │    │  └───────────┘ └───────────┘   │      │
    │  └─────────────────────────────────┘    └─────────────────────────────────┘      │
    └─────────────────────────────────────────────────────────────────────────────────┘
                                                                              │
         ┌────────────────────────────────────────────────────────────────────┘
         │
         ▼
    ┌─────────┐
    │ HTTP    │
    │ Response│
    └─────────┘
```

---

## Network Topology

### Mermaid Graph

```mermaid
graph TB
    subgraph Internet["Internet"]
        USERS[Users]
    end
    
    subgraph Edge["Edge Layer"]
        CDN[CDN/WAF]
        DNS[DNS]
    end
    
    subgraph K8s["Kubernetes Cluster"]
        ING[Ingress]
        
        subgraph App["Application Layer"]
            API1[API Pod 1]
            API2[API Pod 2]
            API3[API Pod 3]
        end
        
        subgraph Data["Data Layer"]
            DF1[DragonFlyDB 1]
            DF2[DragonFlyDB 2]
            DF3[DragonFlyDB 3]
            
            N1[NATS 1]
            N2[NATS 2]
            N3[NATS 3]
        end
        
        subgraph Monitor["Monitoring"]
            PROM[Prometheus]
            GRAF[Grafana]
        end
    end
    
    USERS --> DNS
    DNS --> CDN
    CDN --> ING
    ING --> API1
    ING --> API2
    ING --> API3
    
    API1 --> DF1
    API1 --> DF2
    API1 --> DF3
    
    API1 --> N1
    API1 --> N2
    API1 --> N3
    
    API1 --> PROM
    API2 --> PROM
    API3 --> PROM
    
    PROM --> GRAF
```
