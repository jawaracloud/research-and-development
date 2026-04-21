#!/bin/bash
# Automatically generated script: to-upper
# Purpose: Convert a file's contents to uppercase.

tr '[:lower:]' '[:upper:]' < "${1:--}"
