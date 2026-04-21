# Recent Files

A bash script designed to: **Show files modified in the last 24 hours.**

## Usage

```bash
./recent-files.sh
```

## Command Implementation

```bash
find . -type f -mtime -1
```
