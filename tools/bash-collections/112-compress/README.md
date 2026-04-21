# Compress

A bash script designed to: **Streamlined compression for target folders.**

## Usage

```bash
./compress.sh
```

## Command Implementation

```bash
tar -czvf "${1%/}.tar.gz" "$1"
```
