# Run Until Fail

A bash script designed to: **Continually trigger a local script indefinitely until finding an eventual failure context.**

## Usage

```bash
./run-until-fail.sh
```

## Command Implementation

```bash
count=0; while "$@"; do count=$((count+1)); echo "Run \$count succeeded."; done; echo "Failed on run \$((count+1))"
```
