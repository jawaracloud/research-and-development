#!/bin/bash
# Automatically generated script: todo-list
# Purpose: Query active TODO manifest contents directly.

cat ~/TODO.md 2>/dev/null || echo "No TODOs"
