# Find Empty

A bash script designed to: **Locate all empty directories.**

## Usage

```bash
./find-empty.sh
```

## Command Implementation

```bash
find "${1:-.}" -empty
```
