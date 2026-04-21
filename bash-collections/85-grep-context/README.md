# Grep Context

A bash script designed to: **Display X lines of context around a match.**

## Usage

```bash
./grep-context.sh
```

## Command Implementation

```bash
grep -C "${2:-3}" "$1" "$3"
```
