#!/bin/bash

#Script to update ip-host entries on a file, from a file that includes the new IP - host entry.
#Input: $1 file to be updated - $2 (optional) csv file with NewIP,NewHost.
#If the $2 parameter is not set, the script will create the ip-host.csv list from the CSPC DB
#Created by: isavenda, alemonto & cesmoren

#Replace Function
replace_ip_host() {
	#Function to Check for duplicates on the $1 file
	#After the duplicate check it will update or add the ip-host entry

	#To avoid problems the $1 file is modify to be delimited by one space
	#and should not have spaces at the end of the entries
	sed -E -i 's/\s+/ /g' $1
	sed -E -i 's/\s+$//g' $1

	#count aux variables
	count=0
	count2=0
	count_del=0
	count_repl=0

	#A backup with the timestamp of the $1 file is created
	cp $1{,-$(date +%m%d%Y_%H%M).bk}

	#Loop to check the ip-host entries
	while IFS="," read -r ip host; do
		count=$(($count + 1))
		echo -e "Checking Entry $count/$(wc -l $2 | cut -d ' ' -f 1): $ip - $host"

		#Duplicate ip delete
		lines=($(grep -E "\b$ip\b" $1))
		n=${#lines[@]}
		for ((i=0 ; i < $n ; i=i+2));do
			if [[ ! (${lines[i]} == $ip && ${lines[i+1]} == $host) ]];then
				sed -i -E "/^${lines[i]}\s+\(?${lines[i+1]}\)?/d" $1
				count_del=$(($count_del + 1))
			fi
		done

		#Duplicate host delete
		lines=($(grep -E "\b$host$" $1))
		n=${#lines[@]}
		for ((i=0 ; i < $n ; i=i+2));do
			if [[ ! (${lines[i]} == $ip && ${lines[i+1]} == $host) ]];then
				sed -i -E "/^${lines[i]}\s+${lines[i+1]}/d" $1
				count_del=$(($count_del + 1))
			fi
		done

		#After the duplicate check
		#First checks if the host already exist to update the ip
		OLD_IP=$(grep -E "\b$host$" $1)
		if [[ $? -eq 0 ]];then
			#Replace the ip if the host already exists
			OLD_IP=$(echo $OLD_IP | cut -d ' ' -f 1 | head -1)
			#echo -e "\tReplacing Old_ip: $OLD_IP with NewIp: $ip\n"
			sed -i -E "s/^$OLD_IP\s+$host/$ip $host/g" $1
			count_repl=$(($count_repl + 1))
		else
			#If the host doesnt exist, will check if the ip exist and replace it
			OLD_HOST=$(grep -E "\b$ip\b" $1)
			if [[ $? -eq 0 ]];then
				#Replace the host if the ip already exists and the host doesnt
				OLD_HOST=$(echo $OLD_HOST | cut -d ' ' -f 2 | head -1)
				#echo -e "\tReplacing Old_host: $OLD_HOST with NewHost: $host\n"
				sed -i -E "s/^$ip\s+$OLD_HOST/$ip $host/g" $1
				count_repl=$(($count_repl + 1))
			else
				#Add the ip-host entry as neither the ip or the host exist
				#echo -e "\tIp: $ip and Host: $host not found, adding\n"
				echo "$ip $host" >> $1
				count_repl=$(($count_repl + 1))
			fi
		fi
	done < $2

	echo -e "\n$count ip-host checked"
	echo "$count_del ip-host deleted"
	echo -e "$count_repl ip-host updated\n"

	> missing_entries.txt

	#Verify that all the ip-host entries have been updated
	while IFS="," read -r ip host; do
			NEW_IP=$(grep -E "\b$host$" $1 | cut -d ' ' -f 1 | head -1)
			if [[ $NEW_IP == $ip ]];  then
				count2=$(($count2 + 1))
			else
				#if the found ip on the host doesnt match the one needed will append it to a file
				echo $ip,$host >> missing_entries.txt
			fi
	done < $2
	echo -e "$count2 verified update ip-host entries"

	if [[ $count2 -eq $(wc -l $2 | cut -d ' ' -f 1) ]];then
		echo -e "\nAll ip-host entries succesfully verified and updated\n"
	else
		echo -e "\n$(wc -l missing_entries.txt | cut -d ' ' -f 1) ip-host entries missing, check\n"
	fi
}

#Get ip-host.csv list from CSPC DB Function
db_ip_host() {
	#Function to generated the ip-host.csv list from the cspc DB
	#DB temporary root access
	cp /etc/my.cnf{,.bk}
	echo -e "Processing DB Temporary Root Access Request:"
	systemctl stop mysql && echo -e "\tMysql service stopped successfully"
	sed -in '/^\[mysqld\]$/a skip-grant-tables' /etc/my.cnf
	systemctl restart mysql && echo -e '\tMysql service restarted successfully'
	grep -i "skip-grant-tables" /etc/my.cnf > /dev/null && echo -e "\tDatabase temporary root access granted"

	#Create csv file with ip,host of the reachable devices 
	$CSPCHOME/database/mysql/bin/mysql -u root paridb -e "select ipaddress,hostname from discovered_devices where NOT (hostname REGEXP '^[[(]]?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[)]]?$') and status='Discovered';" | sed "s/'/\'/;s/\t/,/g;s/^//;s/$//;s/\n//g" | tail -n +2 > $files/ip_host_list.csv
	echo -e 'Ip - Host CSV File Successfully Created\n'

	#Revert DB root access
	echo -e "Reverting DB Temporary Root Access Request:"
	systemctl stop mysql && echo -e '\tMysql service stopped successfully'
	sed -i '/^skip-grant-tables$/d' /etc/my.cnf
	systemctl restart mysql && echo -e '\tMysql service restarted succesfully'
	diff -q /etc/my.cnf{,.bk} > /dev/null
	[[ $? -eq 0 ]] && echo -e '\tDatabase root access reverted';rm -f /etc/my.cnf.bk || echo -e '\tFailed, my.cnf couldnt be reverted, check /etc/my.cnf'

	#Duplicate Hostname Check
	echo -e "\nChecking for Duplicate Hostnames on $files/ip_host_list.csv File"
	count_del=0
	while IFS="," read -r ip host; do
		lines=($(grep -E "\b$host$" $files/ip_host_list.csv))
			n=${#lines[@]}
		if [[ n -gt 1 ]]; then
			echo -e "\tDeleting duplicates of $host"
			for line in ${lines[@]};do
					sed -i -E "/^$line/d" $files/ip_host_list.csv
			echo -e "\t\tDeleting: $line"
					count_del=$(($count_del + 1))
			done
		fi
	done < $files/ip_host_list.csv
	echo -e "Hostname Duplicate Checked Finished: $count_del Duplicates Deleted"
	echo -e "\nDB Ip-Host file exported on $files/ip_host_list.csv"
}

# Optional Argument for ip-host.csv file
ARG2=${2:-db}

#SCRIPT RUN
#Check root user
if [[ $(id -u) -ne 0 ]]
then
echo -e 'Sorry, script should be executed as root in order to work propperly!'
exit 1;
fi

#Check custom directory to be created
files="/home/collectorlogin/custom/update_ip_host"
[[ ! -d /home/collectorlogin/custom ]] && mkdir /home/collectorlogin/custom
[[ ! -d /home/collectorlogin/custom/update_ip_host ]] && mkdir /home/collectorlogin/custom/update_ip_host

#Check if custom ip-host.csv file has been pass as argument
if [ $ARG2 == "db" ]; then
	echo -e "Update ip-host Script Default Execution"
    echo -e "\nCreating ip-host list from cspc db"
	db_ip_host
	echo -e "\nReplacing ip-host according to $files/ip_host_list.csv file"
	replace_ip_host $1 $files/ip_host_list.csv
else
	echo -e "Update ip-host Script Custom Execution"
    echo -e "\nReplacing ip-host acording to $ARG2 file\n"
	replace_ip_host $1 $ARG2
fi