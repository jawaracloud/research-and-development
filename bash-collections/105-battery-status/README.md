# Battery Status

A bash script designed to: **Read bare-metal battery capacity without bloated software.**

## Usage

```bash
./battery-status.sh
```

## Command Implementation

```bash
cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "No battery"
```
