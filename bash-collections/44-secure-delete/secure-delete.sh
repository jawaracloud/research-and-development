#!/bin/bash
# Automatically generated script: secure-delete
# Purpose: Securely delete a file by overwriting it with random data before unlinking it.

dd if=/dev/urandom of="$1" bs=4k count=$(($(wc -c <"$1")/4096+1)) 2>/dev/null; rm -f "$1"
