#!/bin/bash
# This Script handles Multiple user management, group modifying, deleting multiple users and groups
# 
# Author: Cesar Moreno
#
#userlistfile=/home/collectorlogin/userlist.txt
userlistfile=~/Desktop/users.txt
username=$(cat $userlistfile | tr 'A-Z' 'a-z')
password="Cis@12cso"
usage () {
cat <<END
usage: $0 [options]
    options:
    -a,     Add Multiple users
    -d,     Delete Multiple Users
    -g      Modify users group
    -G      Delete Groups
    -h      Display help
END
}
# Check if the user is root
root_check ()
{
    uid=$(id -u)
    if [ "$uid" != "0" ]
    then
        echo "This needs to be run from root user"
        exit 1
    fi }
# if none option is given
if [ $# -eq 0 ]
then
usage
fi

root_check

add_users () {
    group () {
        for user in $username 
        do 
            useradd $user -g $groupname
            echo $password | passwd --stdin $user | passwd -e $user
        done }
    nogroup () {
        for user in $username 
        do 
            useradd "$user" 
            echo $password | passwd --stdin "$user" | passwd -e "$user"
        done    }
    printf "Add Users to a group? (y/n) \n"
    read -n 1 -rs
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -r -p "Insert the group for the users: " groupname
        if grep -q "$groupname" /etc/group; then
            printf "The group %s exists, creating Users...\n " "$groupname"
            group
        elif [ $? -ne 0 ]; then
            printf "The group %s doesn't exists, do you want to create it now? \n" "$groupname"
            printf "(y/n)\n"
            read -sr -n 1
            if  [[ $REPLY =~ ^[Yy]$ ]]; then 
            groupadd "$groupname"  
            printf "Group created, Creating users.. \n"
            group
            elif [[ $REPLY =~ ^[Nn]$ ]]; then  
            printf "Creating users only...\n"
            nogroup
            else
            printf "Option not valid, try again."
            exit 1 
            fi
        fi       
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
        printf "Creating users only...\n"
        nogroup        
    fi

    if [ $? -eq 0 ]; then
        echo "$(wc -l $userlistfile) users have been created" 
        tail -n $(wc -l $userlistfile) /etc/passwd
        echo '======================================================================'
        echo  "Users created successfully! use $password to log-in the first time "
        echo '======================================================================'
    else
        echo 'User add failed!'
    fi
    }
del_usrs () {
    del_files () {
        for user in $username 
        do 
            userdel -r "$user"
        done    }
    del_usrs_only () {
        for user in $username 
        do 
            userdel "$user"
        done    }
    printf "Do you want to delete users along with their home directory? (y/n)\n"
    read -rs -n 1
    if [[ $REPLY =~ ^[Yy]$ ]]; then
    del_files
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
    del_usrs_only
    else
    printf "Option not valid, try again. \n"
        exit 2 
    fi
    if [ $? -eq 0 ]; then
    echo "$(wc -l $userlistfile) users have been deleted! " 
    tail -n $(wc -l $userlistfile) /etc/passwd
    else
    echo 'User removal failed!'
    fi
}
add_to_group () {
    read -r -p "Insert the group for the users: " groupname
    for user in $username 
    do 
        usermod -g  "$groupname" "$user"
        echo Adding "$username" to group "$groupname"
    done

    if [ $? -eq 0 ]; then
    echo "$(wc -l $userlistfile) users group have been changed" 
    id "$user"

    else
    echo 'User group change failed!'
    fi
}
del_groups () {
    for group in $username
    do
        groupdel $group 
    done 
    if [ $? -eq 0 ]; then
        echo "$(wc -l $userlistfile) groups deleted" 
        tail -n $(wc -l $userlistfile) /etc/group
    fi
    }

while getopts "adgGh" opt; do
    case "${opt}" in
    a) add_users ;;
    d) del_usrs ;;
    g) add_to_group ;;
    G) del_groups ;;
    h) # Display help
        usage ;;
    *) printf 'Option not valid, try again:\n'
        usage
        exit 1;;
    esac
done