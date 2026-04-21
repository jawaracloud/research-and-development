# Weather

A bash script designed to: **Show the current weather in the terminal.**

## Usage

```bash
./weather.sh
```

## Command Implementation

```bash
curl -s "wttr.in/${1:-}?0"
```
