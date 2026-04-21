#!/bin/bash
# Automatically generated script: cpu-hogs
# Purpose: Identity processes consuming the most CPU.

ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head
