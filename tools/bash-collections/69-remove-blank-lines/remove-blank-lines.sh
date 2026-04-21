#!/bin/bash
# Automatically generated script: remove-blank-lines
# Purpose: Strip all blank lines from a file.

sed '/^[[:space:]]*$/d' "$1"
