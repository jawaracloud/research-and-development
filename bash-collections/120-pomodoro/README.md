# Pomodoro

A bash script designed to: **Simplistic 25 minute worker, 5 minute rest cycle via timer wrapper.**

## Usage

```bash
./pomodoro.sh
```

## Command Implementation

```bash
echo "Work for 25m"; sleep 1500; echo "Break for 5m" | wall; sleep 300; echo "Back to work!" | wall
```
