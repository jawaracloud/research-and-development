# Remove Blank Lines

A bash script designed to: **Strip all blank lines from a file.**

## Usage

```bash
./remove-blank-lines.sh
```

## Command Implementation

```bash
sed '/^[[:space:]]*$/d' "$1"
```
