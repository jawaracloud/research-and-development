#!/bin/bash
# Automatically generated script: ssh-key-copy
# Purpose: Append your public key to a remote server seamlessly.

cat ~/.ssh/id_rsa.pub | ssh "$1" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
