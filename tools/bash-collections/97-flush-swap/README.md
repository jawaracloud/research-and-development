# Flush Swap

A bash script designed to: **Deactivate and reactivate swap space strictly.**

## Usage

```bash
./flush-swap.sh
```

## Command Implementation

```bash
sudo swapoff -a && sudo swapon -a
```
