#!/bin/bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

BUCKET_NAME="bucket-name"
BUCKET_BACKUP="bucket-backups"
DIR="s3://$BUCKET_NAME/recordings"
LOGO="/root/scripts/logo.png"
top_left="overlay=x=(main_w-overlay_w)/(main_w-overlay_w):y=(main_h-overlay_h)/(main_h-overlay_h)"
top_right="overlay=x=(main_w-overlay_w):y=(main_h-overlay_h)/(main_h-overlay_h)"
center="overlay=x=(main_w-overlay_w)/2:y=(main_h-overlay_h)/2"
transcode_folder="/root/scripts/transcode_process/"
distribution_id="000000000"

# Bitrates
a=("1920x1080" "2500k")
b=("1280x720" "1500k")
c=("640x480" "750k")

parameter="-iname \"*.mp4\" -o -iname \"*.mov\" -o -iname \"*.avi\" -o -iname \"*.m4a\" -o -iname \"*.mp3\" -o -iname \"*.MOV\" -o -iname \"*.MP4\""

for i in `/usr/local/bin/aws s3 ls s3://$BUCKET_NAME/insights/ | awk '{print $2}'`; do 
	if [ ! -d "$transcode_folder" ]; then
		mkdir -p $transcode_folder
	fi
	cd $transcode_folder
	mkdir -p $i
	/usr/local/bin/aws s3 cp s3://$BUCKET_NAME/recordings/$i  ./$i --exclude "*" --include "*.flv" --include "*.mp4" --include "*.mov" --include "*.avi" --include "*.m4a" --include "*.mp3" --include "*.MP4" --include "*.MOV" --recursive
	/usr/local/bin/aws s3 cp --recursive s3://$BUCKET_NAME/recordings/$i s3://$BUCKET_BACKUP/recordings/$i
	/usr/local/bin/aws s3 rm s3://$BUCKET_NAME/insights/$i --recursive
	for newfile in `find $i -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.m4a" -o -iname "*.mp3" -o -iname "*.MOV" -o -iname "*.MP4"`; do 
		error () {
			if [ $? -eq "0" ]; then
                                logger "$newfile is converted/added to the $1"
                        else
                                logger "$newfile is not converted/added to the $1"
                        fi
		}
		if [[ ${newfile##*.} = .m4a ]]; then
			logger "mp4a file is converting to mp3 format."
			ffmpeg -i $newfile -vn -ar 44100 -ac 2 -ab 64k -f mp3 "${newfile%.*}"".mp3"
			error "mp3"
		elif [ ${newfile##*.} = "mp4" ] || [ ${newfile##*.} = "mov" ] || [ ${newfile##*.} = "MP4" ] || [ ${newfile##*.} = "MOV" ]; then
			cp $newfile $newfile"_bck"
			ffmpeg -y -i $newfile"_bck" -i $LOGO -filter_complex $top_left -c:v libx264 -tune zerolatency -preset slow -profile:v baseline -map 0 -movflags +faststart $newfile
			echo "ffmpeg -y -i $newfile"_bck" -i $LOGO -filter_complex $top_left -c:v libx264 -tune zerolatency -preset slow -profile:v baseline -map 0 -movflags +faststart $newfile" > /tmp/sil.txt
			error "Logo"
			ffmpeg -i $newfile -vn -ar 44100 -ac 2 -ab 64k -f mp3 "${newfile%.*}"".mp3"
			error "mp3"
			rm -rf $newfile"_bck"
			file_name=$(basename $newfile | sed 's/\(.*\)\..*/\1/')
			cd $i
			ffmpeg -i $(basename $newfile) -map 0:v:0 -map 0:a:0 -map 0:v:0 -map 0:a:0 -map 0:v:0 -map 0:a:0 -s:v:0 ${a[0]} -c:v:0 libx264 -b:v:0 ${a[1]} -s:v:1 ${b[0]} -c:v:1 libx264 -b:v:1 ${b[1]} -s:v:2 ${c[0]} -c:v:2 libx264 -b:v:2 ${c[1]} -c:a aac -f hls -hls_playlist_type vod -master_pl_name ${file_name}.m3u8 -hls_segment_filename ${file_name}_%v/${file_name}%03d.ts -use_localtime_mkdir 1 -var_stream_map "v:0,a:0,name:1080p v:1,a:1,name:720p v:2,a:2,name:480p" -hls_flags split_by_time -hls_time 3 ${file_name}_%v.m3u8
			error "HLS"
			cd ..
		else
			echo "$newfile"
		fi
		/usr/local/bin/aws s3 sync . $DIR --exclude "*.sh" --exclude "*.png"
		logger "All files were copied to S3."
		/usr/local/bin/aws s3 rm s3://$BUCKET_NAME/insights/$i --recursive
		aws cloudfront create-invalidation --distribution-id $distribution_id --paths "/recordings/$i*"

	done
	rm -rf $i
done

IFS=$SAVEIFS
