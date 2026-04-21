# Stopwatch

A bash script designed to: **Loop terminal printing stopwatch counter.**

## Usage

```bash
./stopwatch.sh
```

## Command Implementation

```bash
start=$(date +%s); while true; do echo -ne "$(($(date +%s) - start)) seconds\r"; sleep 1; done
```
