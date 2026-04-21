# Docker Clean All

A bash script designed to: **Purge dead Docker images, containers and volumes fully.**

## Usage

```bash
./docker-clean-all.sh
```

## Command Implementation

```bash
docker system prune -af --volumes
```
