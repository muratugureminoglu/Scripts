#!/bin/bash

APPS="live"

jwt_token() {

    header='{"alg":"HS256","typ":"JWT"}'
    payload='{"iat": 1516239022}'

    header_base64=$(echo -n "$header" | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')
    payload_base64=$(echo -n "$payload" | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

    data="$header_base64.$payload_base64"

    secret=`cat /usr/local/antmedia/webapps/$APPS/WEB-INF/red5-web.properties |grep "jwtSecretKey" | awk -F "=" '{print $2}'`
    signature=$(echo -n "$data" | openssl dgst -sha256 -hmac "$secret" -binary | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

    jwt="$data.$signature"
    echo "$jwt"
}

JWT_TOKEN=$(jwt_token)
echo $JWT_TOKEN
