# Text To Html

A bash script designed to: **Quick wrap simple text inside HTML pre tags.**

## Usage

```bash
./text-to-html.sh
```

## Command Implementation

```bash
echo "<pre>$(cat "${1:-}")</pre>"
```
