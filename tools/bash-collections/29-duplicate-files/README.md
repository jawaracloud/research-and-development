# Duplicate Files

A bash script designed to: **Find duplicate files inside a directory tree using md5sum.**

## Usage

```bash
./duplicate-files.sh
```

## Command Implementation

```bash
find . -type f -exec md5sum {} + | sort | uniq -w32 -dD
```
