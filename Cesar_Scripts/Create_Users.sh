#!/bin/bash

userlistfile=/home/collectorlogin/userlist.txt
username=$(cat $userlistfile | tr 'A-Z' 'a-z')
password="Cis@12cso"
read -r -p "Insert the group for the users: " groupname

for user in $username 
do 
    useradd $user -g $groupname
    echo $password | passwd --stdin $user | passwd -e $user
done

if [ $? -eq 0 ]; then
echo "$(wc -l $userlistfile) users have been created" 
tail -n $(wc -l $userlistfile) /etc/passwd

else
echo 'User add failed!'
fi
