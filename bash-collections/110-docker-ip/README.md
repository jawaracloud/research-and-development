# Docker Ip

A bash script designed to: **Isolate and read a Docker Container's exact IP address.**

## Usage

```bash
./docker-ip.sh
```

## Command Implementation

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
```
