# Dir Size

A bash script designed to: **Get the human-readable total size of a directory.**

## Usage

```bash
./dir-size.sh
```

## Command Implementation

```bash
du -sh "${1:-.}"
```
