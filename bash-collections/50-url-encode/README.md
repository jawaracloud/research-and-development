# Url Encode

A bash script designed to: **URL-encode a string using jq.**

## Usage

```bash
./url-encode.sh
```

## Command Implementation

```bash
echo "$1" | jq -sRr @uri
```
