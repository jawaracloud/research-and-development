# Lowercase Names

A bash script designed to: **Rename all files in a folder to lowercase.**

## Usage

```bash
./lowercase-names.sh
```

## Command Implementation

```bash
for f in *; do [ -e "$f" ] && mv -v "$f" "$(echo "$f" | tr '[:upper:]' '[:lower:]')"; done
```
