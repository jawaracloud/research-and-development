#!/bin/bash
# Automatically generated script: weather
# Purpose: Show the current weather in the terminal.

curl -s "wttr.in/${1:-}?0"
