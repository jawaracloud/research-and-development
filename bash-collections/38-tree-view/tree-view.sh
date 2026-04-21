#!/bin/bash
# Automatically generated script: tree-view
# Purpose: Display a visual tree of files without needing the `tree` command.

find "${1:-.}" -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
