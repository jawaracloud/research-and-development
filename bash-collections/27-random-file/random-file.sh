#!/bin/bash
# Automatically generated script: random-file
# Purpose: Output a random file from the current directory.

find . -type f | awk 'BEGIN{srand()} {print rand() "\t" $0}' | sort -n | cut -f2- | head -n 1
