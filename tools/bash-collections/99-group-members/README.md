# Group Members

A bash script designed to: **Discover members connected to specific UNIX groups.**

## Usage

```bash
./group-members.sh
```

## Command Implementation

```bash
getent group "$1" | awk -F: '{print $4}'
```
