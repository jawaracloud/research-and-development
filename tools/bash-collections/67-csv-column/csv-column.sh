#!/bin/bash
# Automatically generated script: csv-column
# Purpose: Extract a specific column from a CSV file.

awk -F, -v col="${2:-1}" '{print $col}' "$1"
