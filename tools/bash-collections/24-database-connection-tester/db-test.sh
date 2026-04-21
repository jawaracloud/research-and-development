#!/bin/bash
# Database Connection Tester: Test connectivity to various databases
#
# Requirements:
#   - mysql-client (for MySQL)
#   - postgresql-client (for Postgres)
#   - redis-tools (for Redis)
#   - mongosh (for MongoDB)
#   - nc (netcat) for generic port check
#
# Usage:
#   ./db-test.sh <type> <host> <port> [user] [password] [db]

set -eo pipefail

TYPE=$1
HOST=$2
PORT=$3
USER=$4
PASS=$5
DB=$6

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <mysql|postgres|redis|mongodb|port> <host> <port> [user] [pass] [db]"
    echo ""
    echo "Examples:"
    echo "  $0 mysql localhost 3306 root password my_db"
    echo "  $0 postgres localhost 5432 postgres password postgres"
    echo "  $0 redis localhost 6379"
    echo "  $0 port google.com 443"
    exit 1
}

if [ $# -lt 3 ]; then
    usage
fi

log_info() {
    echo -e "${YELLOW}[TESTING]${NC} Connecting to $TYPE at $HOST:$PORT..."
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} Successfully connected to $TYPE!"
}

log_error() {
    echo -e "${RED}[FAILED]${NC} Could not connect to $TYPE at $HOST:$PORT"
    echo -e "Error: $1"
    exit 1
}

# Generic Port Check
check_port() {
    if nc -zv -w 5 "$HOST" "$PORT" 2>&1; then
        return 0
    else
        return 1
    fi
}

log_info

# First check if port is even open
if ! check_port; then
    log_error "Port $PORT is closed or unreachable on $HOST"
fi

case $TYPE in
    mysql)
        if ! command -v mysql &> /dev/null; then log_error "mysql client not installed"; fi
        if mysql -h "$HOST" -P "$PORT" -u "$USER" -p"$PASS" "$DB" -e "SELECT 1" &>/dev/null; then
            log_success
        else
            log_error "MySQL authentication failed or server rejected connection"
        fi
        ;;
    postgres)
        if ! command -v psql &> /dev/null; then log_error "psql client not installed"; fi
        if PGPASSWORD="$PASS" psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -c "SELECT 1" &>/dev/null; then
            log_success
        else
            log_error "PostgreSQL authentication failed or server rejected connection"
        fi
        ;;
    redis)
        if ! command -v redis-cli &> /dev/null; then log_error "redis-cli not installed"; fi
        if [ -n "$PASS" ]; then
            AUTH_CMD="-a $PASS"
        fi
        if redis-cli -h "$HOST" -p "$PORT" $AUTH_CMD ping | grep -q "PONG"; then
            log_success
        else
            log_error "Redis PING failed"
        fi
        ;;
    mongodb)
        if ! command -v mongosh &> /dev/null; then log_error "mongosh not installed"; fi
        if mongosh --host "$HOST" --port "$PORT" -u "$USER" -p "$PASS" --eval "db.adminCommand('ping')" &>/dev/null; then
            log_success
        else
            log_error "MongoDB authentication failed"
        fi
        ;;
    port)
        log_success
        ;;
    *)
        log_error "Unsupported database type: $TYPE"
        ;;
esac
