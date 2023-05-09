#!/bin/bash

publisher=$1
rtmp_url=$2
input_url=$3

for (( i=1; i <= $publisher; ++i )); do
	ffmpeg -nostdin -re -i $input_url -c copy -f flv rtmp://$rtmp_url/WebRTCAppEE/stream$i 2> /dev/null &
done

