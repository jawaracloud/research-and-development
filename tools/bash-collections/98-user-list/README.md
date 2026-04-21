# User List

A bash script designed to: **Rapidly list all user accounts on the system.**

## Usage

```bash
./user-list.sh
```

## Command Implementation

```bash
cut -d: -f1 /etc/passwd
```
