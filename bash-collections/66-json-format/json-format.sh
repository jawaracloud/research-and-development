#!/bin/bash
# Automatically generated script: json-format
# Purpose: Pretty print JSON from standard input.

cat ${1:--} | jq .
