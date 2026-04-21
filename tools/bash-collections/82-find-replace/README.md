# Find Replace

A bash script designed to: **Find and replace strings in a file across the board.**

## Usage

```bash
./find-replace.sh
```

## Command Implementation

```bash
sed -i "s/$1/$2/g" "$3"
```
