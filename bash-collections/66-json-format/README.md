# Json Format

A bash script designed to: **Pretty print JSON from standard input.**

## Usage

```bash
./json-format.sh
```

## Command Implementation

```bash
cat ${1:--} | jq .
```
