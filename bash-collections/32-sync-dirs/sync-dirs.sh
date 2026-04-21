#!/bin/bash
# Automatically generated script: sync-dirs
# Purpose: Quickly synchronize two directories using rsync.

rsync -avh --update "$1/" "$2/"
