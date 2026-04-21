# History Stat

A bash script designed to: **Generate statistics on most frequently used bash commands.**

## Usage

```bash
./history-stat.sh
```

## Command Implementation

```bash
history | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n10
```
