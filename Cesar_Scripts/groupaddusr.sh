#!/bin/bash

userlistfile=/home/collectorlogin/userlist.txt
username=$(cat $userlistfile | tr 'A-Z' 'a-z')
read -r -p "Insert the group for the users: " groupname

for user in $username 
do 
    usermod -g  "$groupname" "$user"
    echo "Adding "$username" to group "$groupname""
done

if [ $? -eq 0 ]; then
echo "$(wc -l $userlistfile) users group have been changed" 
tail -n $(wc -l "$userlistfile") /etc/passwd

else
echo 'User group change failed!'
fi