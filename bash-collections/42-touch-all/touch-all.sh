#!/bin/bash
# Automatically generated script: touch-all
# Purpose: Update the modified timestamp of all nested files.

find "${1:-.}" -exec touch {} +
