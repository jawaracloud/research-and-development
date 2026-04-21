# Random File

A bash script designed to: **Output a random file from the current directory.**

## Usage

```bash
./random-file.sh
```

## Command Implementation

```bash
find . -type f | awk 'BEGIN{srand()} {print rand() "\t" $0}' | sort -n | cut -f2- | head -n 1
```
