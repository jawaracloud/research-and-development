# Ping Sweep

A bash script designed to: **Perform a ping sweep on a /24 subnet.**

## Usage

```bash
./ping-sweep.sh
```

## Command Implementation

```bash
subnet=${1:-192.168.1}; for ip in $(seq 1 254); do ping -c 1 -W 1 $subnet.$ip | grep "64 bytes" & done; wait
```
