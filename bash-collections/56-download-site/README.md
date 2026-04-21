# Download Site

A bash script designed to: **Download an entire webpage for offline viewing.**

## Usage

```bash
./download-site.sh
```

## Command Implementation

```bash
wget -q -m -p -E -k -K -np "$1"
```
