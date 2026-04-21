# Cpu Hogs

A bash script designed to: **Identity processes consuming the most CPU.**

## Usage

```bash
./cpu-hogs.sh
```

## Command Implementation

```bash
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head
```
