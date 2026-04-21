#!/bin/bash
# Automatically generated script: dir-size
# Purpose: Get the human-readable total size of a directory.

du -sh "${1:-.}"
