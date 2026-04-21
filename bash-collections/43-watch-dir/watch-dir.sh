#!/bin/bash
# Automatically generated script: watch-dir
# Purpose: Watch for changes in a directory.

watch -n 1 "ls -lhA ${1:-.}"
