#!/bin/bash
# Automatically generated script: git-clean-branches
# Purpose: Delete completely merged git branches to clear space.

git branch --merged | grep -v '\*' | xargs -n 1 git branch -d
