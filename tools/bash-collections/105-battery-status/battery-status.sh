#!/bin/bash
# Automatically generated script: battery-status
# Purpose: Read bare-metal battery capacity without bloated software.

cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "No battery"
