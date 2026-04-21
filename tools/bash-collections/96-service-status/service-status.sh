#!/bin/bash
# Automatically generated script: service-status
# Purpose: Checks if a systemd service is active.

systemctl is-active "$1"
