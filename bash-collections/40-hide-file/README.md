# Hide File

A bash script designed to: **Hide a file by prefixing it with a dot.**

## Usage

```bash
./hide-file.sh
```

## Command Implementation

```bash
mv "$1" ".${1##*/}"
```
