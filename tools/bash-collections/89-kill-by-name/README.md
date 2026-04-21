# Kill By Name

A bash script designed to: **Terminate process rapidly by its name instead of PID.**

## Usage

```bash
./kill-by-name.sh
```

## Command Implementation

```bash
pkill -f "$1"
```
