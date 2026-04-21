# Shorten Url

A bash script designed to: **Shorten a URL using is.gd API.**

## Usage

```bash
./shorten-url.sh
```

## Command Implementation

```bash
curl -s "https://is.gd/create.php?format=simple&url=$1"
```
