#!/bin/bash
# Automatically generated script: stopwatch
# Purpose: Loop terminal printing stopwatch counter.

start=$(date +%s); while true; do echo -ne "$(($(date +%s) - start)) seconds\r"; sleep 1; done
