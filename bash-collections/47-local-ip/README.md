# Local Ip

A bash script designed to: **Get your local network IP address.**

## Usage

```bash
./local-ip.sh
```

## Command Implementation

```bash
hostname -I | awk '{print $1}'
```
