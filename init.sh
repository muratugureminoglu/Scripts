#!/bin/bash
INITIALIZED=/usr/local/antmedia/conf/initialized
if [ ! -f "$INITIALIZED" ]
then
  ## Local IPV4

  export LOCAL_IPv4=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

  # $HOSTNAME ip-172-30-0-216
  HOST_NAME=`hostname`

  HOST_LINE="$LOCAL_IPv4 $HOST_NAME"
  grep -Fxq "$HOST_LINE" /etc/hosts
  
  OUT=$?
  if [ $OUT -ne 0 ]; then   

    echo  "$HOST_LINE" | tee -a /etc/hosts
    OUT=$?

    if [ $OUT -ne 0 ]; then
      echo "Cannot write hosts file"
      exit $OUT
    fi
  fi 
  ## Instance ID
  export INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`

  ## Add Initial User with curl
  RESULT=`curl -s -H "Content-Type: application/json" -X POST -d '{"email":"JamesBond","password":"123456","fullName":"Bond James Bond"}' http://localhost:5080/rest/addInitialUser`

  echo ${RESULT} | grep --quiet ":true"  

  if [ $? = 1 ]
  then
    echo "Cannot create initial user"
    echo "sleep 3 ; /usr/local/antmedia/conf/init.sh"  | at now
    exit $OUT
  fi

  touch $INITIALIZED
fi
