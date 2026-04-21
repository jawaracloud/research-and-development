# Zombie Kill

A bash script designed to: **Scans for and wipes completely dead Zombie processes.**

## Usage

```bash
./zombie-kill.sh
```

## Command Implementation

```bash
ps aux | awk '$8=="Z" {print $2}' | xargs -r kill -9
```
