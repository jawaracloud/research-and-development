# Sync Dirs

A bash script designed to: **Quickly synchronize two directories using rsync.**

## Usage

```bash
./sync-dirs.sh
```

## Command Implementation

```bash
rsync -avh --update "$1/" "$2/"
```
