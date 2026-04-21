# Architecture Diagrams for Pub/Sub Demo with Golang and DragonFlyDB

This file contains Mermaid diagrams that represent the complete architecture of the demo. Each diagram focuses on a different aspect of the system.

---

## Overall System Architecture

This diagram shows the core services and their interactions.

```mermaid
flowchart LR
    subgraph DockerCompose [Docker Compose Deployment]
        P(Publisher Service)
        S(Subscriber Service)
        D(DragonFlyDB Service)
    end
    P -->|Publishes Message| D
    S -->|Subscribes to Channel| D
```

---

## Docker Compose Architecture

This diagram illustrates how the containers are interconnected in the Docker Compose network.

```mermaid
graph TD
    A[Publisher Container] -- "Env: REDIS_ADDR, CHANNEL" --> B[DragonFlyDB Container]
    C[Subscriber Container] -- "Env: REDIS_ADDR, CHANNEL" --> B
    B -- "Network: pubsub_demo" --> A
    B -- "Network: pubsub_demo" --> C
```

---

## Message Flow

This sequence diagram shows the flow of a message from publication to consumption, including latency measurement.

```mermaid
sequenceDiagram
    participant P as Publisher
    participant D as DragonFlyDB
    participant S as Subscriber
    P->>D: Publish(JSON Message)
    D->>S: Send Message to Subscribers
    S->>S: Process Message & Measure Latency
```

---

## Publisher Internal Flow

This flowchart depicts the internal logic of the Publisher service.

```mermaid
flowchart TD
    A[Start Publisher Service]
    B[Load Env Variables: REDIS_ADDR, CHANNEL]
    C[Connect to DragonFlyDB]
    D[Enter Publish Loop]
    E[Create & Marshal JSON Message]
    F[Publish Message to Channel]
    G[Wait 2 Seconds]
    H[Handle SIGTERM/SIGINT for Graceful Shutdown]
    
    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> D
    D --> H
```

---

## Subscriber Internal Flow

This flowchart shows the internal process of the Subscriber service.

```mermaid
flowchart TD
    A[Start Subscriber Service]
    B[Load Env Variables: REDIS_ADDR, CHANNEL]
    C[Connect to DragonFlyDB]
    D[Subscribe to Channel]
    E[Wait for Subscription Confirmation]
    F[Launch Goroutine to Receive Messages]
    G[Unmarshal JSON Message]
    H[Calculate Latency]
    I[Process Message]
    J[Handle SIGTERM/SIGINT for Graceful Shutdown]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    I --> J
```

---

These diagrams collectively provide a comprehensive view of the architecture—from container deployment with Docker Compose, through the message flow between the Publisher and Subscriber, to the inner workings of each service.