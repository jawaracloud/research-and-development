#!/bin/bash
# Automatically generated script: git-update-all
# Purpose: Update ALL internal git repositories within current directory.

find . -type d -name .git -execdir git pull origin HEAD \;
