#!/bin/bash
# Automatically generated script: user-list
# Purpose: Rapidly list all user accounts on the system.

cut -d: -f1 /etc/passwd
