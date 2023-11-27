#!/bin/bash
userlistfile=/home/collectorlogin/users.txt
username=$(cat $userlistfile | tr 'A-Z' 'a-z')
password="Cis@12cso"
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
            useradd $user 
            echo $password | passwd --stdin $user | passwd -e $user
        done    }
    printf "Add Users to a group? (y/n) \n"
    read -n 1 -rs
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -r -p "Insert the group for the users: " groupname
        if grep -q $groupname /etc/group; then
            printf "The group %s exists, creating Users...\n    " "$groupname"
            group
        elif [ $? -ne 0 ]; then
            printf "The group %s doesn't exists, do you want to create it now? \n" "$groupname"
            printf "(y/n)\n"
            read -sr -n 1
            if  [[ $REPLY =~ ^[Yy]$ ]]; then 
            groupadd $groupname  
            printf "Group created, Creating users.. \n"
            group
            elif [[ ! $REPLY =~ ^[Yy]$ ]]; then  
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
            userdel -r $user
        done    }
    del_usrs_only () {
        for user in $username 
        do 
            userdel $user
        done    }
    printf "Do you want to delete users along with their home directory? (y/n)\n"
    read -rs -n 1
    if [[ $REPLY =~ ^[Yy]$ ]]; then
    del_files
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
    del_usrs_only
    else
    printf "Option not valid, try again."
        exit 2 
    fi
    if [ $? -eq 0 ]; then
    echo "$(wc -l $userlistfile) users have been deleted! " 
    tail -n $(wc -l $userlistfile) /etc/passwd
    else
    echo 'User removal failed!'
    fi
}
