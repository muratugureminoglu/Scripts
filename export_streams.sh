#!/bin/bash
#
# Export Ant Media Server streams (all or specific stream).
#
# Usage:
#   ./export_streams.sh <app_name>             -> export all streams
#   ./export_streams.sh <app_name> <stream_id> -> export only given stream

APP_NAME=$1
STREAM_ID=$2
CONFIG_FILE="/usr/local/antmedia/webapps/$APP_NAME/WEB-INF/red5-web.properties"
BASE_URL="http://localhost:5080"

LIMIT=250
OFFSET=0
OUT_FILE="${APP_NAME}_streams.json"

if [ -z "$APP_NAME" ]; then
  echo "Usage:"
  echo "  $0 <app_name>             -> export all streams"
  echo "  $0 <app_name> <stream_id> -> export only given stream"
  exit 1
fi

jwt_token() {
    iat=$(date +%s)
    header='{"alg":"HS256","typ":"JWT"}'
    payload="{\"iat\":$iat}"

    header_base64=$(echo -n "$header" | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')
    payload_base64=$(echo -n "$payload" | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

    data="$header_base64.$payload_base64"

    secret=$(grep "^jwtSecretKey=" "$CONFIG_FILE" | cut -d'=' -f2)
    signature=$(echo -n "$data" | openssl dgst -sha256 -hmac "$secret" -binary | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

    echo "$data.$signature"
}

JWT_TOKEN=$(jwt_token)
JWT_SECRET=$(grep "^jwtSecretKey=" "$CONFIG_FILE" | cut -d'=' -f2)
jwtControlEnabled=$(grep "^jwtControlEnabled=" "$CONFIG_FILE" | cut -d'=' -f2)

if [ "$jwtControlEnabled" = "true" ] && [ -n "$JWT_SECRET" ]; then
    CURL_CMD=(curl -s -H "Authorization: Bearer $JWT_TOKEN" -H "accept: application/json")
else
    CURL_CMD=(curl -s -H "accept: application/json")
fi

# -------------------------
# EXPORT ALL STREAMS
# -------------------------
if [ -z "$STREAM_ID" ]; then

  echo "[]" > "$OUT_FILE"

  while true; do
    RESPONSE=$("${CURL_CMD[@]}" \
      "$BASE_URL/$APP_NAME/rest/v2/broadcasts/list/$OFFSET/$LIMIT")

    COUNT=$(echo "$RESPONSE" | jq 'length')

    [ "$COUNT" -eq 0 ] && break

    jq -s '.[0] + (.[1] | map(del(.anyoneWatching)))' \
      "$OUT_FILE" <(echo "$RESPONSE") > /tmp/streams.json

    mv /tmp/streams.json "$OUT_FILE"

    OFFSET=$((OFFSET + LIMIT))
  done

  echo "All streams exported to: $OUT_FILE"
  echo "Total streams: $(jq 'length' "$OUT_FILE")"

# -------------------------
# EXPORT SINGLE STREAM
# -------------------------
else
  "${CURL_CMD[@]}" "$BASE_URL/$APP_NAME/rest/v2/broadcasts/$STREAM_ID" \
    | jq 'del(.anyoneWatching)' > "${APP_NAME}_${STREAM_ID}.json"

  echo "Stream exported to: ${APP_NAME}_${STREAM_ID}.json"
fi
