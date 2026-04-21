# Ssh Key Copy

A bash script designed to: **Append your public key to a remote server seamlessly.**

## Usage

```bash
./ssh-key-copy.sh
```

## Command Implementation

```bash
cat ~/.ssh/id_rsa.pub | ssh "$1" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```
