# Calc

A bash script designed to: **Calculate simple floating point math equations via CLI.**

## Usage

```bash
./calc.sh
```

## Command Implementation

```bash
echo "scale=4; $*" | bc -l
```
