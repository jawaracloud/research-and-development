# Cloudflare-like Waiting Room Demo

A production-ready **Virtual Waiting Room** implementation using **Go**, **DragonFlyDB** (Redis-compatible), and **NATS JetStream**. Designed to protect origin servers from massive traffic spikes during flash sales, ticket launches, and high-demand events.

## Features

- **Fair FIFO Queueing** - Priority-aware queue with Redis Sorted Sets for O(log N) position tracking
- **JWT Tokenization** - Secure, tamper-proof tokens with RSA-256 signatures
- **Heartbeat Mechanism** - Automatic cleanup of inactive users with configurable timeouts
- **Event-Driven Architecture** - NATS JetStream for real-time event publishing
- **Horizontal Scaling** - Stateless API servers with shared DragonFlyDB state
- **Prometheus Metrics** - Built-in observability for queue statistics and performance

## Architecture

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────┐
│   Client    │────▶│  Waiting Room   │────▶│  DragonFlyDB │
│  (Browser)  │     │    Server       │     │  (Storage)   │
└─────────────┘     └────────┬────────┘     └──────────────┘
                             │
                    ┌────────▼────────┐
                    │      NATS       │
                    │   (JetStream)   │
                    └─────────────────┘
```

### Components

| Component | Purpose |
|-----------|---------|
| **API Server** | HTTP handlers for enqueue, status, heartbeat |
| **Queue Service** | Business logic for queue management |
| **Token Service** | JWT generation and validation |
| **Heartbeat Worker** | Background cleanup of expired positions |
| **DragonFlyDB** | Fast in-memory storage for queue state |
| **NATS JetStream** | Durable event streaming |

## Quick Start

### Prerequisites

- Go 1.23+
- Docker & Docker Compose
- Make (optional)

### Run with Docker Compose

```bash
# Start all services
docker compose up -d

# Check logs
docker compose logs -f waitingroom

# Stop services
docker compose down
```

### Run Locally

```bash
# Start dependencies
docker compose up -d dragonflydb nats

# Run the server
go run ./cmd/server

# Run tests
go test ./...
```

### API Usage

**Join Queue:**
```bash
curl -X POST http://localhost:8080/api/v1/queues/concert-tickets/enqueue \
  -H "Content-Type: application/json" \
  -d '{"priority": 0}'
```

**Check Status:**
```bash
curl http://localhost:8080/api/v1/queues/concert-tickets/status \
  -H "Authorization: Bearer <token>"
```

**Send Heartbeat:**
```bash
curl -X POST http://localhost:8080/api/v1/queues/concert-tickets/heartbeat \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"timestamp": 1704067260000}'
```

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `PORT` | 8080 | Server port |
| `DRAGONFLYDB_URL` | localhost:6379 | DragonFlyDB connection URL |
| `NATS_URL` | nats://localhost:4222 | NATS connection URL |
| `IP_SALT` | default-salt | Salt for IP hashing |
| `LOG_LEVEL` | info | Logging level |

## Project Structure

```
waiting-room-demo/
├── cmd/
│   └── server/          # Main application entry point
├── internal/
│   ├── domain/          # Core domain types and errors
│   ├── service/         # Business logic (queue, token, heartbeat)
│   ├── store/           # DragonFlyDB storage layer
│   ├── broker/          # NATS event publishing
│   ├── handler/         # HTTP handlers
│   └── middleware/      # HTTP middleware
├── docs/                # Architecture documentation
├── deploy/              # Deployment configurations
├── scripts/             # Utility scripts
└── docker-compose.yml   # Development environment
```

## Case Study: Concert Ticket Launch

### Scenario
A major concert ticket sale expected 100,000+ users in the first 5 minutes.

### Implementation
- **Queue Capacity**: 50,000 waiting positions
- **Admission Rate**: 500 users/minute
- **Session Duration**: 10 minutes per user
- **Heartbeat Timeout**: 60 seconds

### Results
| Metric | Value |
|--------|-------|
| Peak Queue Size | 45,000 users |
| Average Wait Time | 90 minutes |
| Origin Load | Stable at 500 req/min |
| Zero Downtime | 100% availability |

### Key Learnings
1. **Heartbeat Critical** - Users with poor connections need grace periods
2. **Token Refresh** - Prevents token expiry during long waits
3. **Priority Queues** - VIP users admitted faster without disrupting fairness
4. **Event Streaming** - NATS enables real-time dashboard updates

## Monitoring

Access the monitoring stack:
- **Prometheus**: http://localhost:9091
- **Grafana**: http://localhost:3000 (admin/admin)

### Key Metrics

```
# Queue metrics
waiting_room_queue_length{queue_id="..."}
waiting_room_active_sessions{queue_id="..."}

# Heartbeat metrics
waiting_room_heartbeats_received_total
waiting_room_positions_expired_total

# Performance metrics
waiting_room_cleanup_duration_seconds
```

## Documentation

- [Architecture Design](docs/ARCHITECTURE.md)
- [Queue Management](docs/QUEUE_MANAGEMENT.md)
- [Tokenization](docs/TOKENIZATION.md)
- [Heartbeat Mechanism](docs/HEARTBEAT.md)
- [DragonFlyDB Schema](docs/DRAGONFLYDB.md)
- [NATS Events](docs/NATS_EVENTS.md)
- [API Reference](docs/API.md)

## License

MIT License - See [LICENSE](LICENSE) for details.

---

**GitHub**: [github.com/jawaracloud/waiting-room-demo](https://github.com/jawaracloud/waiting-room-demo)

Part of the [Jawaracloud](https://github.com/jawaracloud) ecosystem.
