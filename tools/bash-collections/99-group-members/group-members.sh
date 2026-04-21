#!/bin/bash
# Automatically generated script: group-members
# Purpose: Discover members connected to specific UNIX groups.

getent group "$1" | awk -F: '{print $4}'
