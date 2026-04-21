# Check Host

A bash script designed to: **Check if a host is up or down.**

## Usage

```bash
./check-host.sh
```

## Command Implementation

```bash
ping -c 1 "$1" &> /dev/null && echo "up" || echo "down"
```
