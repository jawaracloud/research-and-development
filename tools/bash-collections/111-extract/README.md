# Extract

A bash script designed to: **Universal extraction standard (tar, unzip, gunzip auto-resolving).**

## Usage

```bash
./extract.sh
```

## Command Implementation

```bash
tar -xf "$1" 2>/dev/null || unzip "$1" 2>/dev/null || gunzip "$1" 2>/dev/null
```
