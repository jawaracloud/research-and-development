#!/bin/bash
# Automatically generated script: calc
# Purpose: Calculate simple floating point math equations via CLI.

echo "scale=4; $*" | bc -l
