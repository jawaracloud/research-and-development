#!/bin/bash
# Automatically generated script: grep-context
# Purpose: Display X lines of context around a match.

grep -C "${2:-3}" "$1" "$3"
