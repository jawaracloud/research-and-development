# Mem Hogs

A bash script designed to: **Identity processes consuming the most Memory.**

## Usage

```bash
./mem-hogs.sh
```

## Command Implementation

```bash
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head
```
