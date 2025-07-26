#!/bin/bash
#
# Before proceeding install this package: apt install heif-gdk-pixbuf
#

IFS=$'\n'

for file in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS; do
    if [[ "$file" =~ \.([hH][eE][iI][cC])$ ]]; then
        output="${file%.*}.png"
        heif-convert "$file" "$output" >> /tmp/heic-convert.log 2>&1
    fi
done
