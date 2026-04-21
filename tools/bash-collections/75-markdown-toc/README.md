# Markdown Toc

A bash script designed to: **Generate a Table of Contents for a Markdown document.**

## Usage

```bash
./markdown-toc.sh
```

## Command Implementation

```bash
grep -E '^#{1,6} ' "$1" | sed 's/^#//g'
```
