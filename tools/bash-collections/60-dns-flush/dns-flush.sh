#!/bin/bash
# Automatically generated script: dns-flush
# Purpose: Attempt to flush DNS cache over systemd/init.

sudo systemctl restart systemd-resolved 2>/dev/null || sudo /etc/init.d/dns-clean restart
