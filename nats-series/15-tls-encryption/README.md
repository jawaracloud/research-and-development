# 15 — TLS Encryption

> **Type:** How-To  
> **Phase:** Foundations

## Overview

This lesson enables TLS encryption between NATS clients and the server, ensuring all messages are encrypted in transit — essential for any production deployment.

## Step 1: Generate certificates (local lab)

```bash
# Create CA
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 1826 -key ca.key -out ca.crt \
  -subj "/CN=NATS-CA/O=Jawaracloud"

# Create server cert
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
  -subj "/CN=localhost/O=Jawaracloud"
openssl x509 -req -days 365 -in server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

# Create client cert (for mTLS)
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr \
  -subj "/CN=my-service/O=Jawaracloud"
openssl x509 -req -days 365 -in client.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt
```

## Step 2: Server TLS configuration

`nats-server.conf`:
```
tls {
  cert_file: "./certs/server.crt"
  key_file:  "./certs/server.key"
  ca_file:   "./certs/ca.crt"
  verify:    true            # require client certs (mTLS)
  timeout:   5
}
```

## Step 3: Client — TLS only (server cert verification)

```go
tlsConfig := &tls.Config{
    RootCAs: loadCACert("certs/ca.crt"),
}
nc, err := nats.Connect("tls://localhost:4222",
    nats.Secure(tlsConfig),
)
```

## Step 4: Client — mTLS (mutual TLS)

```go
cert, _ := tls.LoadX509KeyPair("certs/client.crt", "certs/client.key")
caCert, _ := os.ReadFile("certs/ca.crt")
caCertPool := x509.NewCertPool()
caCertPool.AppendCertsFromPEM(caCert)

tlsConfig := &tls.Config{
    Certificates: []tls.Certificate{cert},
    RootCAs:      caCertPool,
}
nc, err := nats.Connect("tls://localhost:4222",
    nats.Secure(tlsConfig),
)
```

## Docker Compose with TLS

```yaml
services:
  nats:
    image: nats:2.10-alpine
    command: -c /etc/nats/nats-server.conf
    volumes:
      - ./certs:/etc/nats/certs:ro
      - ./nats-server.conf:/etc/nats/nats-server.conf:ro
    ports:
      - "4222:4222"
```

## Verify TLS

```bash
# Check server TLS
openssl s_client -connect localhost:4222 -CAfile certs/ca.crt

# NATS CLI with TLS
nats pub test "hello" \
  --tlscert certs/client.crt \
  --tlskey certs/client.key \
  --tlsca certs/ca.crt \
  --server tls://localhost:4222
```

---
*Part of the 100-Lesson NATS Series.*
