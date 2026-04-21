# Logs Shipper

A simple Bash script to archive and transfer logs to a remote server via SCP.

## Features

✅ Automates log compression (tar.gz)
✅ Secure transfer via SCP
✅ Cleanup of temporary files after transfer
✅ Timestamped archives for easy management

## Requirements

1. **SCP**: Secure copy command
2. **SSH Access**: To the destination server

## Usage

```bash
./ship.sh /var/log/nginx user@remote-host:/backups/logs/
```

## Real-World Case Study: Off-site Log Storage

### The Challenge
A security policy required logs to be stored on a separate physical server to prevent tampering in case of a server compromise.

### Results
- ✅ Successfully implemented automated off-site log rotation
- ✅ Guaranteed availability of logs for forensic analysis
- ✅ Reduced storage pressure on application servers
