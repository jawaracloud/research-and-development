# Trim Whitespace

A bash script designed to: **Trim leading and trailing whitespace from a file.**

## Usage

```bash
./trim-whitespace.sh
```

## Command Implementation

```bash
sed 's/^[[:space:]]*//;s/[[:space:]]*$//' "$1"
```
