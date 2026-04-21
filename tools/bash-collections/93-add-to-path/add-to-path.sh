#!/bin/bash
# Automatically generated script: add-to-path
# Purpose: Add the target directory permanently to .bashrc PATH.

echo "export PATH=\$PATH:$(readlink -f "$1")" >> ~/.bashrc
