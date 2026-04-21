#!/bin/bash
# Automatically generated script: flatten-dir
# Purpose: Move all nested files into the root of the specified directory.

find "${1:-.}" -mindepth 2 -type f -exec mv -i {} "${1:-.}" \;
