#!/bin/bash
# Automatically generated script: date-to-epoch
# Purpose: Transpile an expressed data representation to unix epoch.

date -d "$1" +%s
