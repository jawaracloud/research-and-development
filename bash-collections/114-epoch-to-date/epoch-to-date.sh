#!/bin/bash
# Automatically generated script: epoch-to-date
# Purpose: Convert a unix epoch integer to readable datestamp.

date -d @"$1"
