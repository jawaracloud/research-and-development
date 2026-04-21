# Date To Epoch

A bash script designed to: **Transpile an expressed data representation to unix epoch.**

## Usage

```bash
./date-to-epoch.sh
```

## Command Implementation

```bash
date -d "$1" +%s
```
