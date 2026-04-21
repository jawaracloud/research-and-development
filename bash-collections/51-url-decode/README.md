# Url Decode

A bash script designed to: **URL-decode a string using pure bash.**

## Usage

```bash
./url-decode.sh
```

## Command Implementation

```bash
echo -e "${1//%/\\x}"
```
