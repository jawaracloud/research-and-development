#!/bin/bash
# Automatically generated script: trim-whitespace
# Purpose: Trim leading and trailing whitespace from a file.

sed 's/^[[:space:]]*//;s/[[:space:]]*$//' "$1"
