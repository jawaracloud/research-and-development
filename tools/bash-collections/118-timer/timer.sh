#!/bin/bash
# Automatically generated script: timer
# Purpose: Notify when X minutes have expired natively.

sleep $(($1 * 60)) && echo "Timer done!" | wall
