# Disk Usage

A bash script designed to: **Display file system usage, omitting loops/tmpfs.**

## Usage

```bash
./disk-usage.sh
```

## Command Implementation

```bash
df -hT | grep -v 'tmpfs|cdrom'
```
