#!/bin/bash
# Automatically generated script: duplicate-files
# Purpose: Find duplicate files inside a directory tree using md5sum.

find . -type f -exec md5sum {} + | sort | uniq -w32 -dD
