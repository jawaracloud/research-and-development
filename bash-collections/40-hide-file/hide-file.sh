#!/bin/bash
# Automatically generated script: hide-file
# Purpose: Hide a file by prefixing it with a dot.

mv "$1" ".${1##*/}"
