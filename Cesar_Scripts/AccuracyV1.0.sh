#!/bin/bash

#Variable de entradas
working_dir="/home/collectorlogin/accuracy/"
input_file="${working_dir}/unreachable_devices.csv"
read -srp "Insert snmpv2 community: " snmp_comunnity
read -rp "Insert ssh user for the devices: " ssh_usr
read -srp "Insert ssh password: " pwd_ssh
[[ ! -d $working_dir ]] && mkdir $working_dir
#Check root user
if [[ $(id -u) -ne 0 ]]
then
echo -e 'Sorry, script should be executed as root in order to work propperly!'
exit 1;
fi

db_ip_un() {
	#Function to generate the Unreachable ip list from the cspc DB
	#DB temporary root access
	cp /etc/my.cnf{,.bk}
	echo -e "Processing DB Temporary Root Access Request:"
	systemctl stop mysql && echo -e "\tMysql service stopped successfully"
	sed -in '/^\[mysqld\]$/a skip-grant-tables' /etc/my.cnf
	systemctl restart mysql && echo -e '\tMysql service restarted successfully'
	grep -i "skip-grant-tables" /etc/my.cnf > /dev/null && echo -e "\tDatabase temporary root access granted"

    # Unreachable devices list exported from Data Base
    $CSPCHOME/database/mysql/bin/mysql -u root paridb -e "select ipaddress from discovered_devices where status='Failed';" | tail -n +2 | tr '\n' ','| sed "s/ /,/g;$ s/.$//" > $input_file
	echo -e 'Unreachable Devices CSV Successfully Created\n'

	#Revert DB root access
	echo -e "Reverting DB Temporary Root Access Request:"
	systemctl stop mysql && echo -e '\tMysql service stopped successfully'
	sed -i '/^skip-grant-tables$/d' /etc/my.cnf
	systemctl restart mysql && echo -e '\tMysql service restarted succesfully'
	diff -q /etc/my.cnf{,.bk} > /dev/null
	[[ $? -eq 0 ]] && echo -e '\tDatabase root access reverted';rm -f /etc/my.cnf.bk || echo -e '\tFailed, my.cnf couldnt be reverted, check /etc/my.cnf'
}


creds_ex_from_SF (){ 
# Global credentials
# Export seed file
$CSPCHOME/cli/bin/export_seedfile.sh exportmanageddevicedetails _exportdir /tmp/SF _ip-f $input_file
mv /tmp/SF/*.csv /tmp/SF/sf.csv
# \command do not modifies your aliases setup, as it is overriding it just for this call.
\mv -f /tmp/SF $working_dir
# Seed File formating
sed -i '1,40d' $working_dir/SF/sf.csv
# ssh credentials extraction & Duplicates removal
awk -F ',' '{ print $17,$18 }' $working_dir/SF/sf.csv | uniq > $working_dir/ssh.txt

# snmpv2 credentials extraction
awk -F ',' '{ print $9,$10 }' $working_dir/SF/sf.csv | uniq > $working_dir/snmpv2.txt
awk -F ',' '{
    if ($9=="")
    { 
        print "Snmp RO Credentials not found";
        exit 1;
    }
    else if ($10=="")
    { 
        print "Snmp RW Credentials not found";
        exit 1;
    }}' $working_dir/snmpv2.txt
# ask if want to keep files 

}
# Dav for unreachable devices commanduy
job_schedule_davjob.sh runnow _protocol snmp,ssh _tryAllVersions true _overrideEnableFailed true _runDavForUnreachable true _rundiscovery false _ip-l "$(cat $input_file)"
# Show DAV report done to the devices
show_report_davreport.sh _ip-l "$(cat $input_file)"

# proceso
for ip in $input_file 
do
    ping -c2 $ip
    snmpwalk -v 2c -c "$snmp_comunnity" $ip sysName.0
    
    ssh ssh_usr@$ip -p $pwd_ssh
done > device_status.txt
