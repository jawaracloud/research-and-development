# Nginx Log Analyzer

A lightweight Bash tool to extract quick insights from Nginx access logs.

## Features

✅ Identifies top visiting IP addresses
✅ Lists most requested URLs
✅ Shows HTTP status code distribution
✅ No external dependencies (uses standard awk/sort/uniq)

## Usage

```bash
./analyze.sh /var/log/nginx/access.log
```

## Real-World Case Study: Traffic Spike Investigation

### The Challenge
An application experienced a sudden spike in traffic that caused performance issues. The team needed to quickly identify if this was a DDoS attack or legitimate heavy usage.

### The Solution
They ran this analyzer on the latest access log.

### Results
- ✅ Identified a single IP address making 50,000 requests in 10 minutes
- ✅ Blocked the malicious IP using firewall
- ✅ Restored service performance in under 5 minutes
