#!/bin/bash

BASE_URL="http://localhost:5080"
APPNAME="WebRTCAppEE"
CONFIG_FILE="/usr/local/antmedia/webapps/$APP_NAME/WEB-INF/red5-web.properties"

LIMIT=250
OFFSET=0

TMP_FILE="/tmp/${APPNAME}_stream_ids.txt"
> "$TMP_FILE"

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
# EXPORT STREAM IDS
# -------------------------
while true; do
  RESPONSE=$("${CURL_CMD[@]}" \
    "$BASE_URL/$APPNAME/rest/v2/broadcasts/list/$OFFSET/$LIMIT")

  COUNT=$(echo "$RESPONSE" | jq 'length')

  [ "$COUNT" -eq 0 ] && break

  echo "$RESPONSE" | jq -r '.[].streamId' >> "$TMP_FILE"

  OFFSET=$((OFFSET + LIMIT))
done

TOTAL=$(wc -l < "$TMP_FILE")
echo ">>> Total streams collected: $TOTAL"
echo

# -------------------------
# ESTART STREAMS
# -------------------------
while read -r ID; do
  [ -z "$ID" ] && continue

  echo "Restarting stream: $ID"

  STOP_CMD=(
    "${CURL_CMD[@]}"
    -X POST
    "$BASE_URL/$APPNAME/rest/v2/broadcasts/$ID/stop"
  )

  "${STOP_CMD[@]}"

    sleep 0.005

  START_CMD=(
    "${CURL_CMD[@]}"
    -X POST
    "$BASE_URL/$APPNAME/rest/v2/broadcasts/$ID/start"
  )

  "${START_CMD[@]}"

  sleep 0.05
done < "$TMP_FILE"

echo
echo ">>> All streams restarted successfully."
