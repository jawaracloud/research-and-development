# Watch Dir

A bash script designed to: **Watch for changes in a directory.**

## Usage

```bash
./watch-dir.sh
```

## Command Implementation

```bash
watch -n 1 "ls -lhA ${1:-.}"
```
