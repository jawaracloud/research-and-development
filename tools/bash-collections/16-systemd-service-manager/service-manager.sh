#!/bin/bash
# Systemd Service Manager: A simple CLI to manage systemd services
#
# Usage:
#   ./service-manager.sh <action> <service-name>
#   ./service-manager.sh status nginx

set -e

ACTION=$1
SERVICE=$2

if [ -z "$ACTION" ] || [ -z "$SERVICE" ]; then
    echo "Usage: $0 <start|stop|restart|status|enable|disable> <service-name>"
    exit 1
fi

case $ACTION in
    start|stop|restart|enable|disable)
        echo "Running: sudo systemctl $ACTION $SERVICE"
        sudo systemctl $ACTION $SERVICE
        ;;
    status)
        sudo systemctl status $SERVICE
        ;;
    *)
        echo "Invalid action: $ACTION"
        exit 1
        ;;
esac
