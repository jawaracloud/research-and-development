# Socat Network Utilities

A collection of Bash scripts using socat for network forwarding and relay operations.

## Features

✅ TCP port forwarding
✅ UDP relay
✅ UNIX socket forwarding
✅ SSL/TLS wrapper
✅ Lightweight network proxy
✅ Cross-platform compatibility

## What is Socat?

Socat is a command line utility that establishes two bidirectional byte streams and transfers data between them. It's often called the "Swiss Army knife" of networking tools.

## Included Scripts

### bash.sh: TCP Port Forwarding

Forwards traffic from a local port to a remote host/port.

```bash
# Basic port forwarding from local port 6000 to 127.0.0.1:5000
socat TCP4-LISTEN:6000,reuseaddr,fork TCP4:127.0.0.1:5000
```

## Requirements

1. **socat**: Installed on your system

## Installation

```bash
# Install socat
apt install socat
# or for RHEL/CentOS
yum install socat

# Make script executable
chmod +x bash.sh
```

## Usage Examples

### Forward Local Port to Remote Service
```bash
# Forward localhost:6000 → example.com:80
./bash.sh

# Custom ports
socat TCP4-LISTEN:8080,reuseaddr,fork TCP4:google.com:80
```

### Forward UDP Traffic
```bash
# Forward UDP traffic
socat UDP-RECV:53,reuseaddr,fork UDP:8.8.8.8:53
```

### Forward to UNIX Socket
```bash
# Forward to UNIX socket
socat TCP-LISTEN:8080,reuseaddr,fork UNIX-CONNECT:/var/run/docker.sock
```

## Real-World Case Study: Database Remote Access

### The Challenge
A developer needed to access a PostgreSQL database running on a remote server without exposing the port publicly:

- Database only available on localhost:5432 on the remote server
- No VPN connection between local and remote networks
- Need secure access for local development

### The Solution
They used socat port forwarding:

```bash
# On remote server
socat TCP-LISTEN:5432,reuseaddr,fork TCP:localhost:5432

# On local machine
socat TCP-LISTEN:5433,reuseaddr,fork TCP:remote-server-ip:5432

# Connect locally
psql -h localhost -p 5433
```

### Results
- ✅ Secure database access without exposing port
- ✅ No changes to firewall rules
- ✅ Fast and reliable
- ✅ Encrypted traffic when using SSL

## Advanced: SSL Forwarding

```bash
# With SSL encryption
socat OPENSSL-LISTEN:443,cert=/path/to/cert.pem TCP:localhost:80
```

## Common Use Cases

1. **Port Forwarding**: Access remote services locally
2. **Debug Network Traffic**: Troubleshoot network connections
3. **Bridge Protocols**: TCP ↔ UDP
4. **Socket Relay**: Forward between different network types
5. **Remote Shell**: Create secure shell sessions

## Troubleshooting

### "Address already in use"
```bash
# Find and kill existing process
sudo lsof -i :6000
sudo kill -9 <pid>
```

### Connection refused
```bash
# Check if remote service is running
nc -zv remote-host 1234
```
