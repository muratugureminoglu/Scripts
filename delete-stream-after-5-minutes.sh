#!/bin/bash

BASE_URL="http://localhost:5080/live/rest/v2/broadcasts"
CURRENT_TIME=$(date +%s)

# Function to get all broadcasts
get_all_broadcasts() {
  curl -s "${BASE_URL}/list/0/10" | jq -c '.[]'
}

# Function to delete a stream
delete_stream() {
  local stream_id=$1
  echo "Deleting stream: $stream_id"
  curl -s -X 'DELETE' "${BASE_URL}/${stream_id}" && echo "Stream $stream_id deleted."
}

# Main process
echo "Checking all streams..."
ALL_BROADCASTS=$(get_all_broadcasts)

if [ -z "$ALL_BROADCASTS" ]; then
  echo "No active streams found."
  exit 0
fi

# Process each broadcast
echo "$ALL_BROADCASTS" | while IFS= read -r BROADCAST; do
  STREAM_ID=$(echo "$BROADCAST" | jq -r '.streamId')
  START_TIME_MS=$(echo "$BROADCAST" | jq -r '.startTime')
  START_TIME=$((START_TIME_MS / 1000)) # Convert milliseconds to seconds
  ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

  if [ "$ELAPSED_TIME" -gt 300 ]; then # 300 seconds = 5 minutes
    echo "Stream $STREAM_ID has been running for more than 5 minutes. Deleting..."
    delete_stream "$STREAM_ID"
  else
    echo "Stream $STREAM_ID is within 5 minutes. Skipping."
  fi
done

echo "Stream check complete."
