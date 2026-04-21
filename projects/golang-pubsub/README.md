# Pub/Sub Demo with Golang and DragonFlyDB

This project demonstrates the Publisher/Subscriber pattern using Golang and DragonFlyDB. It consists of two services:

1. **Publisher Service (pub.go)** - Publishes messages to a channel
2. **Subscriber Service (subscriber.go)** - Subscribes to the channel and processes messages

## Prerequisites

- Go 1.21 or higher
- Docker and Docker Compose (for containerized deployment)
- DragonFlyDB (automatically set up with Docker Compose)

## How It Works

1. The Publisher service connects to DragonFlyDB and periodically publishes JSON messages to a specified channel.
2. The Subscriber service connects to the same DragonFlyDB instance and subscribes to the channel.
3. When the Publisher sends a message, DragonFlyDB distributes it to all Subscribers.
4. The Subscriber receives the message, processes it, and measures the latency.

## Key Concepts Demonstrated

- **Pub/Sub Pattern**: Decouples message senders (publishers) from receivers (subscribers)
- **Message Distribution**: One message can be received by multiple subscribers
- **Asynchronous Communication**: Publishers and subscribers operate independently
- **Scalability**: Easy to add more publishers or subscribers without changing the code

## Running the Demo

### Using Docker Compose

```bash
# Start all services
docker compose up

# To run with multiple subscriber instances
docker compose up --scale subscriber=3
```

### Running Locally

1. Start DragonFlyDB:
```bash
docker run -p 6379:6379 docker.dragonflydb.io/dragonflydb/dragonfly
```

2. Run the subscriber:
```bash
go run subscriber.go
```

3. Run the publisher:
```bash
go run pub.go
```

## Configuration

Both the publisher and subscriber retrieve configuration via environment variables. The following environment variables control the configuration:

- `REDIS_ADDR` - DragonFlyDB address (default: "localhost:6379")
- `CHANNEL` - Channel name (default: "messages")

Example environment variable usage:
```bash
export REDIS_ADDR=localhost:6379
export CHANNEL=custom-channel
go run pub.go
go run subscriber.go
```

## Message Format

Messages are JSON-encoded with the following structure:

```json
{
  "id": "msg-123",
  "content": "This is message #123",
  "timestamp": "2023-04-18T12:34:56.789Z"
}
```

## Graceful Shutdown

Both services handle SIGINT and SIGTERM signals for graceful shutdown:

1. Stop publishing/receiving messages.
2. Unsubscribe from channels (for subscribers).
3. Close DragonFlyDB connections.
4. Exit cleanly.

## Extensions and Improvements

- Add message acknowledgment
- Implement message persistence
- Add message filtering capabilities
- Implement message replay functionality
- Create a web interface to monitor message flow