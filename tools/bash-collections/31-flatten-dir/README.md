# Flatten Dir

A bash script designed to: **Move all nested files into the root of the specified directory.**

## Usage

```bash
./flatten-dir.sh
```

## Command Implementation

```bash
find "${1:-.}" -mindepth 2 -type f -exec mv -i {} "${1:-.}" \;
```
