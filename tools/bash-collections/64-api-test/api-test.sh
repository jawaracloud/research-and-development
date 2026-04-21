#!/bin/bash
# Automatically generated script: api-test
# Purpose: Check the total response time for an API.

curl -w "\nTime: %{time_total}s\n" -s "$1"
