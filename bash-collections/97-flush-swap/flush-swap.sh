#!/bin/bash
# Automatically generated script: flush-swap
# Purpose: Deactivate and reactivate swap space strictly.

sudo swapoff -a && sudo swapon -a
