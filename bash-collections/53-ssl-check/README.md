# Ssl Check

A bash script designed to: **Verify the expiration dates of an SSL certificate.**

## Usage

```bash
./ssl-check.sh
```

## Command Implementation

```bash
echo | openssl s_client -servername "$1" -connect "${1}:443" 2>/dev/null | openssl x509 -noout -dates
```
