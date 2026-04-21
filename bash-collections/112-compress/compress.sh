#!/bin/bash
# Automatically generated script: compress
# Purpose: Streamlined compression for target folders.

tar -czvf "${1%/}.tar.gz" "$1"
