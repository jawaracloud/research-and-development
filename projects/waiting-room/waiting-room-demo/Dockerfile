# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -o /waitingroom ./cmd/server

# Runtime stage
FROM alpine:3.19

WORKDIR /app

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates tzdata

# Copy binary from builder
COPY --from=builder /waitingroom /app/waitingroom

# Create non-root user
RUN adduser -D -g '' appuser
USER appuser

# Expose ports
EXPOSE 8080 9090

# Run the binary
ENTRYPOINT ["/app/waitingroom"]
