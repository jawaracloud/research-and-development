# Ram Cache Clear

A bash script designed to: **Force UNIX to dump OS buffer cache to free memory.**

## Usage

```bash
./ram-cache-clear.sh
```

## Command Implementation

```bash
sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
```
