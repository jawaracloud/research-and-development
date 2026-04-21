# Random Password

A bash script designed to: **Generate a random, very secure 16-character password.**

## Usage

```bash
./random-password.sh
```

## Command Implementation

```bash
head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c ${1:-16}; echo
```
