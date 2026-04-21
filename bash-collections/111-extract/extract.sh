#!/bin/bash
# Automatically generated script: extract
# Purpose: Universal extraction standard (tar, unzip, gunzip auto-resolving).

tar -xf "$1" 2>/dev/null || unzip "$1" 2>/dev/null || gunzip "$1" 2>/dev/null
