# Dns Flush

A bash script designed to: **Attempt to flush DNS cache over systemd/init.**

## Usage

```bash
./dns-flush.sh
```

## Command Implementation

```bash
sudo systemctl restart systemd-resolved 2>/dev/null || sudo /etc/init.d/dns-clean restart
```
