# To Upper

A bash script designed to: **Convert a file's contents to uppercase.**

## Usage

```bash
./to-upper.sh
```

## Command Implementation

```bash
tr '[:lower:]' '[:upper:]' < "${1:--}"
```
