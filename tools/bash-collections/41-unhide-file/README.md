# Unhide File

A bash script designed to: **Unhide a file by removing the dot prefix.**

## Usage

```bash
./unhide-file.sh
```

## Command Implementation

```bash
f="${1##*/}"; mv "$1" "${f#.}"
```
