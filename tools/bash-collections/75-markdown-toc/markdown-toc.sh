#!/bin/bash
# Automatically generated script: markdown-toc
# Purpose: Generate a Table of Contents for a Markdown document.

grep -E '^#{1,6} ' "$1" | sed 's/^#//g'
