# Service Status

A bash script designed to: **Checks if a systemd service is active.**

## Usage

```bash
./service-status.sh
```

## Command Implementation

```bash
systemctl is-active "$1"
```
