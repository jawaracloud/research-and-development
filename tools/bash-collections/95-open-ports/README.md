# Open Ports

A bash script designed to: **View all listening TCP/UDP sockets instantly.**

## Usage

```bash
./open-ports.sh
```

## Command Implementation

```bash
netstat -tulpn 2>/dev/null || ss -tulpn
```
