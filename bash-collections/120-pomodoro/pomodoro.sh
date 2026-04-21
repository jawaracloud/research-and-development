#!/bin/bash
# Automatically generated script: pomodoro
# Purpose: Simplistic 25 minute worker, 5 minute rest cycle via timer wrapper.

echo "Work for 25m"; sleep 1500; echo "Break for 5m" | wall; sleep 300; echo "Back to work!" | wall
