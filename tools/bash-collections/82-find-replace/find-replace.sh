#!/bin/bash
# Automatically generated script: find-replace
# Purpose: Find and replace strings in a file across the board.

sed -i "s/$1/$2/g" "$3"
