#!/bin/bash
#
# Import Ant Media Server streams (all or specific stream).
#
# Usage:
#   ./generate_tokens.sh <APP_NAME> <STREAM_ID> <MINUTES> <COUNT>
# Example:
#   ./generate_tokens.sh live stream1 10 10000

APP_NAME=$1
STREAM_ID=$2
MINUTES=$3
COUNT=$4

if [ -z "$APP_NAME" ] || [ -z "$STREAM_ID" ] || [ -z "$MINUTES" ] || [ -z "$COUNT" ]; then
  echo "Usage: $0 <APP_NAME> <STREAM_ID> <MINUTES> <COUNT>"
  exit 1
fi

START_TIME=$(date +%s)

EXPIRE_DATE=$(( $(date +%s) + MINUTES*60 ))

OUTPUT_FILE="tokens_${STREAM_ID}.json"

echo "[" > "$OUTPUT_FILE"

for i in $(seq 1 $COUNT); do
  RESPONSE=$(curl -s -X GET "http://localhost:5080/$APP_NAME/rest/v2/broadcasts/$STREAM_ID/token?expireDate=$EXPIRE_DATE&type=play" \
    -H "accept: application/json")

  if [ $i -lt $COUNT ]; then
    echo "  $RESPONSE," >> "$OUTPUT_FILE"
  else
    echo "  $RESPONSE" >> "$OUTPUT_FILE"
  fi
done

echo "]" >> "$OUTPUT_FILE"

END_TIME=$(date +%s) 
DURATION=$((END_TIME - START_TIME))
echo "$COUNT tokens written to $OUTPUT_FILE (valid for $MINUTES minutes)"
echo "Completed in $DURATION seconds"
