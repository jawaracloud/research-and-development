# Api Test

A bash script designed to: **Check the total response time for an API.**

## Usage

```bash
./api-test.sh
```

## Command Implementation

```bash
curl -w "\nTime: %{time_total}s\n" -s "$1"
```
