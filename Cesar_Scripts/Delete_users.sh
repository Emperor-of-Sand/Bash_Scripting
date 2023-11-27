#!/bin/bash

userlistfile=/home/collectorlogin/userlist.txt
username=$(cat $userlistfile | tr 'A-Z' 'a-z')

for user in $username 
do 
    userdel -r $user
done

if [ $? -eq 0 ]; then
echo "$(wc -l $userlistfile) users have been deleted! " 
tail -n $(wc -l $userlistfile) /etc/passwd

else
echo 'User removal failed!'
fi
