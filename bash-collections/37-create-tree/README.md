# Create Tree

A bash script designed to: **Scaffold a standard project directory tree.**

## Usage

```bash
./create-tree.sh
```

## Command Implementation

```bash
mkdir -p "${1:-project}"/{src,bin,docs,tests,lib}
```
