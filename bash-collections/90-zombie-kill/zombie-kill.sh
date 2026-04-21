#!/bin/bash
# Automatically generated script: zombie-kill
# Purpose: Scans for and wipes completely dead Zombie processes.

ps aux | awk '$8=="Z" {print $2}' | xargs -r kill -9
