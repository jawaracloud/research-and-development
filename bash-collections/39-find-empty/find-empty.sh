#!/bin/bash
# Automatically generated script: find-empty
# Purpose: Locate all empty directories.

find "${1:-.}" -empty
