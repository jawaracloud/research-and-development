#!/bin/bash
# Automatically generated script: mem-hogs
# Purpose: Identity processes consuming the most Memory.

ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head
