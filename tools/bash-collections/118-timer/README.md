# Timer

A bash script designed to: **Notify when X minutes have expired natively.**

## Usage

```bash
./timer.sh
```

## Command Implementation

```bash
sleep $(($1 * 60)) && echo "Timer done!" | wall
```
