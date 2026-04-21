# Todo List

A bash script designed to: **Query active TODO manifest contents directly.**

## Usage

```bash
./todo-list.sh
```

## Command Implementation

```bash
cat ~/TODO.md 2>/dev/null || echo "No TODOs"
```
