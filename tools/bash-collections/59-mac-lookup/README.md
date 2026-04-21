# Mac Lookup

A bash script designed to: **Lookup a MAC address vendor via API.**

## Usage

```bash
./mac-lookup.sh
```

## Command Implementation

```bash
curl -s "https://api.macvendors.com/$1"
```
