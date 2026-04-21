# Path List

A bash script designed to: **Print every directory in the PATH variable on separate lines.**

## Usage

```bash
./path-list.sh
```

## Command Implementation

```bash
echo "$PATH" | tr ':' '\n'
```
