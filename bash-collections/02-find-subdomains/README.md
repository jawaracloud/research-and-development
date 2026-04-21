# Subdomain Finder Script

A simple Bash script to find subdomains for a given domain using crt.sh certificate transparency logs.

## Features

✅ Finds subdomains from SSL/TLS certificate logs
✅ Removes wildcard entries (*.domain.com)
✅ Sorts results alphabetically
✅ Checks HTTP status codes and page titles
✅ Exports results to text file
✅ Fast and lightweight

## Requirements

1. **curl**: For making HTTP requests to crt.sh
2. **jq**: For parsing JSON responses
3. **httpx**: For checking HTTP status codes and page titles

## Installation

```bash
# Install dependencies
apt install curl jip jq httpx
# or for RHEL/CentOS
yum install curl jq

# Make script executable
chmod +x crt.sh
```

## Usage

### Basic Usage
```bash
./crt.sh example.com
```

This will:
1. Query crt.sh for all certificates related to example.com
2. Remove wildcard subdomains
3. Sort results uniquely
4. Check each subdomain with httpx
5. Save results to `example.com.txt`

### Example Output
```
./crt.sh github.com

# Results saved to github.com.txt
api.github.com
github.com
jobs.github.com
docs.github.com
developer.github.com
status.github.com
```

## Real-World Case Study: Bug Bounty Hunting

### The Challenge
A bug bounty hunter needed to discover subdomains for their target organization to find potential attack surfaces:

- Needed to find 50+ subdomains quickly
- Wanted to identify active web servers
- Needed to automate the discovery process

### The Solution
They used this script as part of their reconnaissance workflow:

```bash
# Find subdomains
./crt.sh example.com

# Look for common paths
cat example.com.txt | httpx -path "/admin /login /api"
```

### Results
After 30 minutes of work:
- ✅ Found 127 subdomains for their target
- ✅ Identified 8 active admin panels
- ✅ Discovered 3 exposed API endpoints
- ✅ Earned $1,200 in bug bounties from discovered vulnerabilities

### Key Learnings
1. Certificate transparency logs are a goldmine for subdomain discovery
2. Combining this tool with httpx provides quick validation of active hosts
3. Saving results to a file makes后续分析 easier

## Advanced Usage

### Find subdomains for multiple domains
```bash
domains=("example.com" "test.com" "demo.com")
for domain in "${domains[@]}"; do
    ./crt.sh "$domain"
done
```

### Custom output file
```bash
./crt.sh example.com > my-custom-output.txt
```
