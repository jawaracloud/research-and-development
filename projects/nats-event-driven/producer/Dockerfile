# Dockerfile for NATS Producer

# Use the official Go image to build the application
FROM golang:1.23-alpine AS builder

# Set necessary environment variables
ENV CGO_ENABLED=0 GOOS=linux

# Set the current working directory inside the container
WORKDIR /app

# Copy the Go module files and download dependencies
COPY go.mod go.sum ./
COPY ../shared ../shared
RUN go mod tidy

# Copy the source code
COPY . .

# Build the Go application
RUN go build -o producer ./main.go

# Use a minimal image to run the application
FROM alpine:latest

# Install ca-certificates to enable HTTPS connections (needed for `go get` and other network operations)
RUN apk --no-cache add ca-certificates

# Set the current working directory inside the container
WORKDIR /root/

# Copy the built binary from the builder stage
COPY --from=builder /app/producer .

# Command to run the application
ENTRYPOINT ["./producer"]
