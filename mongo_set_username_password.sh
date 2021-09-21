#!/bin/bash

USERNAME="$1"
PASSWORD="$2"

while [ `mongo --eval 'db.User.find()' serverdb --host 127.0.0.1  | grep "_id"|wc -l` == "0" ]; do
	sleep 5
done

for (( i=0; i<`mongo --eval 'db.User.find()' serverdb --host 127.0.0.1  | grep "_id"|wc -l`; ++i)); do
        mongo --eval 'db.User.deleteOne({ "email": "JamesBond" })' serverdb --host 127.0.0.1
done

mongo --eval 'db.User.insert ( {"email":"'$USERNAME'","password":"'$PASSWORD'","userType":"ADMIN"} )' serverdb --host 127.0.0.1
