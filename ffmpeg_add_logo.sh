#!/bin/bash
#
# This script is to keep the original file and add the logo.
# https://www.ffmpeg.org/ffmpeg-filters.html
#

file_destination="/mnt/videos/"
extension="*.mp4"
logo="logo.png"
top_left="overlay=x=(main_w-overlay_w)/(main_w-overlay_w):y=(main_h-overlay_h)/(main_h-overlay_h)"
top_right="overlay=x=(main_w-overlay_w):y=(main_h-overlay_h)/(main_h-overlay_h)"
center="overlay=x=(main_w-overlay_w)/2:y=(main_h-overlay_h)/2"

for file in `find $file_destination -iname "$extension"`; do
	if [[ "$file" == *"original"* ]]; then
		break
	else
		new_file=$(basename $file .mp4)"_original.mp4"
		cp $file $file_destination$new_file
		ffmpeg -y -i $file_destination$new_file -i $logo -filter_complex $top_left $file
	fi
done

