# Tree View

A bash script designed to: **Display a visual tree of files without needing the `tree` command.**

## Usage

```bash
./tree-view.sh
```

## Command Implementation

```bash
find "${1:-.}" -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
```
