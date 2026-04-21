#!/bin/bash
# Automatically generated script: local-ip
# Purpose: Get your local network IP address.

hostname -I | awk '{print $1}'
