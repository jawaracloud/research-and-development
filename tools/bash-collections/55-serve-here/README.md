# Serve Here

A bash script designed to: **Serve the current directory over HTTP.**

## Usage

```bash
./serve-here.sh
```

## Command Implementation

```bash
python3 -m http.server "${1:-8080}"
```
