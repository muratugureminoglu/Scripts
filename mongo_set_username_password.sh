#!/bin/bash

USERNAME="$1"
PASSWORD="$2"

CHECK=$(mongo --eval 'db.User.find()' serverdb --host 127.0.0.1  | grep "_id"|wc -l)

while [ "$CHECK" == "0" ]; do
	sleep 5
done

for (( i=0; i<$CHECK; ++i)); do
        mongo --eval 'db.User.deleteOne({ "email": "JamesBond" })' serverdb --host 127.0.0.1
done

#curl -s -H "Content-Type: application/json" -X POST -d '{"email":"'$USERNAME'","password":"'$PASSWORD'","userType":"ADMIN"}' http://127.0.0.1:5080/rest/v2/users/initial

mongo --eval 'db.User.insert ( {"email":"'$USERNAME'","password":"'$PASSWORD'","userType":"ADMIN"} )' serverdb --host 127.0.0.1
