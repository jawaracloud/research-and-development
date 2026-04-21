# Csv Column

A bash script designed to: **Extract a specific column from a CSV file.**

## Usage

```bash
./csv-column.sh
```

## Command Implementation

```bash
awk -F, -v col="${2:-1}" '{print $col}' "$1"
```
