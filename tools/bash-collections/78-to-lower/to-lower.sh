#!/bin/bash
# Automatically generated script: to-lower
# Purpose: Convert a file's contents to lowercase.

tr '[:upper:]' '[:lower:]' < "${1:--}"
