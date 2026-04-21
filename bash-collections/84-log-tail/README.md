# Log Tail

A bash script designed to: **Tail a log and grep for specific coloured matches live.**

## Usage

```bash
./log-tail.sh
```

## Command Implementation

```bash
tail -f "$1" | grep --color=auto -E "${2:-.}"
```
