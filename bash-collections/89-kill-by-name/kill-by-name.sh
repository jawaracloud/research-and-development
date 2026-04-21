#!/bin/bash
# Automatically generated script: kill-by-name
# Purpose: Terminate process rapidly by its name instead of PID.

pkill -f "$1"
