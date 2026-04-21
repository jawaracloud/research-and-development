# Ip Info

A bash script designed to: **Retrieve geolocation data for an IP.**

## Usage

```bash
./ip-info.sh
```

## Command Implementation

```bash
curl -s "ipinfo.io/${1:-}"
```
