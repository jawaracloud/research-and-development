# Touch All

A bash script designed to: **Update the modified timestamp of all nested files.**

## Usage

```bash
./touch-all.sh
```

## Command Implementation

```bash
find "${1:-.}" -exec touch {} +
```
