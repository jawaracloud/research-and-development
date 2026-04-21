#!/bin/bash
# Automatically generated script: ping-sweep
# Purpose: Perform a ping sweep on a /24 subnet.

subnet=${1:-192.168.1}; for ip in $(seq 1 254); do ping -c 1 -W 1 $subnet.$ip | grep "64 bytes" & done; wait
