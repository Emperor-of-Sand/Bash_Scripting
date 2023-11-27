#!/bin/bash

# Read in the parent directory name from the first argument
parent_dir="/tmp/$1"

# Create the parent directory if it doesn't already exist
if [ ! -d "$parent_dir" ]; then
    mkdir "$parent_dir"
fi

# Loop through the users in the users.list file
while read -r user; do
    # Extract the username and userid from the user line
    username="$(echo "$user" | cut -d':' -f1)"
    userid="$(echo "$user" | cut -d':' -f2)"
    
    # Create the subdirectory for the user
    sub_dir="${parent_dir}/${username}-${userid}"
    mkdir "$sub_dir"
    
    # Change the owner of the subdirectory to the respective user
    chown "$username:$username" "$sub_dir"
done < /tmp/users.list


