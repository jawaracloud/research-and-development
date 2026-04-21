#!/bin/bash
# Automatically generated script: disk-usage
# Purpose: Display file system usage, omitting loops/tmpfs.

df -hT | grep -v 'tmpfs|cdrom'
