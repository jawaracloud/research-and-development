# Database Connection Tester

A versatile Bash script to quickly verify connectivity to various database systems from the command line.

## Features

✅ Supports MySQL, PostgreSQL, Redis, and MongoDB
✅ Generic TCP port check mode
✅ Automatic port-readiness validation (via netcat)
✅ Color-coded success/failure output
✅ Detailed error reporting
✅ Useful for troubleshooting network issues between services

## Requirements

The script requires the respective client tools installed for each database type:
- `mysql-client` for MySQL
- `postgresql-client` for Postgres
- `redis-tools` for Redis
- `mongosh` for MongoDB
- `nc` (netcat) for basic port checks

## Installation

```bash
# Make script executable
chmod +x db-test.sh
```

## Usage

### Test MySQL
```bash
./db-test.sh mysql db.example.com 3306 root mypassword mydb
```

### Test PostgreSQL
```bash
./db-test.sh postgres localhost 5432 postgres password postgres
```

### Test Redis
```bash
./db-test.sh redis cache.local 6379
```

### Basic Port Check
```bash
./db-test.sh port google.com 443
```

## Real-World Case Study: Bastion Host Setup

### The Challenge
A DevOps engineer was setting up a new VPC environment and needed to verify that the Bastion host could reach the RDS (Postgres) and ElastiCache (Redis) instances behind a private security group.

### The Solution
They used `db-test.sh` to confirm connectivity before handing off the environment to the development team.

### Results
- ✅ Identified a missing egress rule in the security group in seconds
- ✅ Verified both authentication and network path
- ✅ Avoided "works on my machine" issues by testing from the actual production environment
