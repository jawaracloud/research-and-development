# Restore File

A bash script designed to: **Restore the most recent timestamped backup.**

## Usage

```bash
./restore-file.sh
```

## Command Implementation

```bash
latest=$(ls -t "${1}".bak-* 2>/dev/null | head -1); [ -n "$latest" ] && cp -a "$latest" "$1"
```
