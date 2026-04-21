# To Lower

A bash script designed to: **Convert a file's contents to lowercase.**

## Usage

```bash
./to-lower.sh
```

## Command Implementation

```bash
tr '[:upper:]' '[:lower:]' < "${1:--}"
```
