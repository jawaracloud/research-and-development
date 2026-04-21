#!/bin/bash
# Automatically generated script: open-ports
# Purpose: View all listening TCP/UDP sockets instantly.

netstat -tulpn 2>/dev/null || ss -tulpn
