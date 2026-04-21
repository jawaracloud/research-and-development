# Backup File

A bash script designed to: **Make a timestamped backup of a file.**

## Usage

```bash
./backup-file.sh
```

## Command Implementation

```bash
cp -a "$1" "$1.bak-$(date +%Y%m%d%H%M%S)"
```
