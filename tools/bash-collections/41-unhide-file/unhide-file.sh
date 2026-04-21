#!/bin/bash
# Automatically generated script: unhide-file
# Purpose: Unhide a file by removing the dot prefix.

f="${1##*/}"; mv "$1" "${f#.}"
