#!/bin/sh

HOST=$1

DATACENTER=$(hostname | awk -F'.' '{print $2}' | tr "[:lower:]" "[:upper:]")

DATA=$(echo -e "GET services\nFilter: host_name = $HOST\nFilter: display_name = System Inventory\nColumns: plugin_output long_plugin_output" | unixcat /usr/local/nagios/var/rw/live | sed 's/;//g' | sed 's/ ,/,/g' | sed 's/, /,/g')

NAME=$(echo $DATA | awk -F, '{print $1}' | tr "[:upper:]" "[:lower:]")
echo "$NAME" | egrep -i "(rlcorp|rlbss)" > /dev/null 2>&1
if [ ! $? -eq 0 ]
then
	echo "$NAME" | grep -i "$DATACENTER" > /dev/null 2>&1
	if [ ! $? -eq 0 ]
	then
		NAME=$(echo "$NAME.$DATACENTER" | tr "[:upper:]" "[:lower:]")
	fi
fi
IP=$(echo $DATA | awk -F, '{print $2}' | awk -F'/' '{print $1}')
MODEL=$(echo $DATA | awk -F, '{print $3}')
SERIAL=$(echo $DATA | awk -F, '{print $4}')
ISVM=$(echo $DATA | awk -F, '{print $5}')
OS=$(echo $DATA | awk -F, '{print $6}')
MEMORY=$(echo $DATA | awk -F, '{print $7}')

echo "$MEMORY" | egrep "^0" > /dev/null 2>&1
if [ $? -eq 0 ] 
then
	MEMORY="0.5GB"
fi

if [ "$MEMORY" = "31G" ]
then
	MEMORY="32G"
fi

if [ "$MEMORY" = "63GB" ]
then
	MEMORY="64GB"
fi

echo "$NAME" | grep -i "xen" > /dev/null 2>&1
if [ $? -eq 0 ] 
then
	MEMORY=$(echo -e "GET services\nFilter: host_name ~ $HOST\nFilter: display_name ~ Xen Total\nColumns: plugin_output" | unixcat /usr/local/nagios/var/rw/live | awk -F':' '{print $2}')
fi

TEMP=$(mysql -uinventory -pwelcome1 -e"use inventory; select hostname from inventory where hostname='${NAME}'")
if [ -z "$TEMP" ]
then
	mysql -uinventory -pwelcome1 -e"use inventory; insert into inventory values ('${NAME}','${IP}','${MODEL}','${SERIAL}','${ISVM}','${OS}','${MEMORY}','${DATACENTER}');"
else
	mysql -uinventory -pwelcome1 -e"use inventory; update inventory set ipaddress='${IP}', model='${MODEL}', serial='${SERIAL}', isvm='${ISVM}', os='${OS}', memory='${MEMORY}', datacenter='${DATACENTER}' where hostname='${NAME}';"
fi

