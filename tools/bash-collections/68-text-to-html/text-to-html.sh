#!/bin/bash
# Automatically generated script: text-to-html
# Purpose: Quick wrap simple text inside HTML pre tags.

echo "<pre>$(cat "${1:-}")</pre>"
