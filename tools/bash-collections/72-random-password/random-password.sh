#!/bin/bash
# Automatically generated script: random-password
# Purpose: Generate a random, very secure 16-character password.

head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c ${1:-16}; echo
