#!/bin/bash
# Automatically generated script: shorten-url
# Purpose: Shorten a URL using is.gd API.

curl -s "https://is.gd/create.php?format=simple&url=$1"
