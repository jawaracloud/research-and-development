# Replace Spaces

A bash script designed to: **Replace all spaces in filenames with underscores.**

## Usage

```bash
./replace-spaces.sh
```

## Command Implementation

```bash
for f in *\ *; do [ -e "$f" ] && mv "$f" "${f// /_}"; done
```
