#!/bin/bash
# Automatically generated script: log-tail
# Purpose: Tail a log and grep for specific coloured matches live.

tail -f "$1" | grep --color=auto -E "${2:-.}"
