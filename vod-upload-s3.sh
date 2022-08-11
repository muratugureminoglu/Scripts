#!/bin/bash
# 
#  Installation Instructions
#
#  apt-get update && apt-get install ffmpeg -y
#  vim [AMS-DIR]/webapps/applications(LiveApp or etc.)/WEB-INF/red5-web.properties
#  settings.vodUploadFinishScript=/Script-DIR/vod-upload-s3.sh
#  sudo service antmedia restart
#

# Check if AWS CLI is installed
if [ -z `which aws` ]; then
        rm -r aws* > /dev/null 2>&1
        echo "Please wait. AWS Client is installing..."
        curl "https://d1vvhvl2y92vvt.cloudfront.net/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" > /dev/null 2>&1
        unzip awscliv2.zip > /dev/null 2>&1
        sudo ./aws/install &
        wait $!
        echo "AWS Client installed."
        rm -r aws*
fi

# Delete the uploaded VoD file from local disk
DELETE_LOCAL_FILE="Y"

AWS_ACCESS_KEY=""
AWS_SECRET_KEY=""
AWS_REGION=""
AWS_BUCKET_NAME=""
$AWS="/usr/local/bin/aws"

#AWS Configuration
$AWS configure set aws_access_key_id $AWS_ACCESS_KEY
$AWS configure set aws_secret_access_key $AWS_SECRET_KEY
$AWS configure set region $AWS_REGION
$AWS configure set output json


tmpfile=$1
mv $tmpfile ${tmpfile%.*}.mp4"_tmp"
ffmpeg -i ${tmpfile%.*}.mp4"_tmp" -c copy -map 0 -movflags +faststart $tmpfile
rm ${tmpfile%.*}.mp4"_tmp"

#Copy with public permission
$AWS s3 cp $tmpfile s3://$AWS_BUCKET_NAME/streams/ --acl public-read

if [ $? != 0 ]; then
        logger "$tmpfile failed to copy file to S3. "
else
        # Delete the uploaded file
        if [ "$DELETE_LOCAL_FILE" == "Y" ]; then
                $AWS s3api head-object --bucket $AWS_BUCKET_NAME --key streams/$(basename $tmpfile)
                if [ $? == 0 ];then
                        rm -rf $tmpfile
                        logger "$tmpfile is deleted."
                fi
        fi
fi
