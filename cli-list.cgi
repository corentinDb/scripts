#!/bin/bash
# CLI directory listing for curl, wget, and other command-line tools
# Returns plain text list of files and directories

echo "Content-Type: text/plain"
echo ""

# List all files with "/" suffix for directories, exclude hidden files
ls -1p | grep -v '^\.'
