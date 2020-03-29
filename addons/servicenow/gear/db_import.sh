#!/bin/sh 

datacenter=$(hostname | awk -F'.' '{print $2}')

for i in $(echo -e "GET hosts\nFilter: groups >= firewalls\nFilter: groups >= switches\nOr: 2\nColumns: host_name address" | unixcat /usr/local/nagios/var/rw/live)
do 
	DATA="$(/usr/bin/snmpwalk -v 2c -c r3@chf0r1t $(echo $i | awk -F';' '{print $2}') SNMPv2-MIB::sysDescr.0 | awk -F'STRING:' '{print $2}' | sed 's/Inc.//g')"
		
	name=$(echo $i | awk -F';' '{print $1}')
	ip=$(echo $i | awk -F';' '{print $2}')
	manufacturer=$(echo $DATA | awk -F',' 'BEGIN {OFS = ",";} {print $1}')
	model=$(echo $DATA | awk -F',' 'BEGIN {OFS = ",";} {print $2}')
	echo "$name,$ip,$manufacturer,$model,$datacenter"

	TEMP=$(mysql -uinventory -pwelcome1 -e"use inventory; select hostname from deviceinventory where hostname='${name}'")
	if [ -z "$TEMP" ]
	then
        	mysql -uinventory -pwelcome1 -e"use inventory; insert into deviceinventory values ('${name}','${ip}','${manufacturer}','${model}','${datacenter}');"
	else
        	mysql -uinventory -pwelcome1 -e"use inventory; update deviceinventory set ipaddress='${ip}', model='${model}', manufacturer='${manufacturer}', datacenter='${datacenter}' where hostname='${name}';"
	fi
done

