# Expand Url

A bash script designed to: **Expand a shortened URL.**

## Usage

```bash
./expand-url.sh
```

## Command Implementation

```bash
curl -sI "$1" | grep -i Location | awk '{print $2}' | tr -d '\r'
```
