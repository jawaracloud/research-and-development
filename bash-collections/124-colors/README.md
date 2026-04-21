# Colors

A bash script designed to: **Paint a palette indicating terminal OS colour code index scale.**

## Usage

```bash
./colors.sh
```

## Command Implementation

```bash
for i in {0..255}; do printf "\e[38;5;%sm%3s\e[0m " "$i" "$i"; [ $(((i+1)%16)) -eq 0 ] && echo; done
```
