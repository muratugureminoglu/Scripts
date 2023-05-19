#!/bin/bash
#
# Change libopenh264 to libx264 for all apps
#

v25="https://antmedia.io/libx264/ffmpeg-linux-x86_64-gpl.jar"
v26="https://antmedia.io/libx264/ffmpeg-5.1.2-1.5.8-linux-x86_64-gpl.jar"
PLUGIN_DIR="/usr/local/antmedia/plugins"
AMS_BASE="/usr/local/antmedia/"

VERSION=$(unzip -p $AMS_BASE/ant-media-server.jar | grep -a "Implementation-Version"|cut -d' ' -f2 | tr -d '\r')


if [ "$(printf '%s\n' "2.6" "$VERSION" | sort -V | head -n1)" = "2.6" ]; then
	wget $v26 -P $PLUGIN_DIR
else
	wget $v25 -P $PLUGIN_DIR
fi

chown -R antmedia.antmedia /usr/local/antmedia/plugins/

LIST_APPS=`ls -d $AMS_BASE/webapps/*/`

for i in $LIST_APPS; do
	echo "" >> $i/WEB-INF/red5-web.properties
	echo "settings.encoding.encoderName=libx264" >> $i/WEB-INF/red5-web.properties
done

systemctl restart antmedia