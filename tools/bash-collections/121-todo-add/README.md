# Todo Add

A bash script designed to: **Inject bullet notes to central TODO manifest file natively.**

## Usage

```bash
./todo-add.sh
```

## Command Implementation

```bash
echo "[ ] $*" >> ~/TODO.md
```
