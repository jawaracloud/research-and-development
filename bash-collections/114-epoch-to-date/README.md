# Epoch To Date

A bash script designed to: **Convert a unix epoch integer to readable datestamp.**

## Usage

```bash
./epoch-to-date.sh
```

## Command Implementation

```bash
date -d @"$1"
```
