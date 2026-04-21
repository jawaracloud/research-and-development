#!/bin/bash
# Automatically generated script: ram-cache-clear
# Purpose: Force UNIX to dump OS buffer cache to free memory.

sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
