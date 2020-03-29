#!/bin/bash
#
# check_snmp_storage_usage
#
# Storage usage check using SNMP
# Copyright (c) 2010 Marko Pavlovic (plugins.from.marko@gmail.com)
# Version: 1.0
# Last Modified: September 2010
# License: GPL v3 (-l for more info)"


PATH=/bin:/usr/bin/:usr/sbin:/usr/local/bin:/usr/local/sbin
PROGPATH=/usr/local/nagios/libexec
export PATH PROGPATH
. $PROGPATH/utils.sh

Help ()
{
        echo
        echo "check_snmp_storage_usage"
	echo "Copyright (c) 2010 Marko Pavlovic (plugins.from.marko@gmail.com)"	
	echo "Version: 1.0"
	echo "Last Modified: September 2010"
	echo "License: GPL v3 (-l for more info)"
        echo
	echo "Note:"
	echo "This plugin does not require any MIB files or additional components."
        echo "Only prerequisite is configured SNMP agent on target host."
        echo "You can use this plugin to check Linux and Windows hosts."
	Usage
}

Usage ()
{
        echo
        echo "Usage: check_snmp_storage_usage <community> <host> <warning> <critical>"
	echo
        echo "community"
        echo "	community name for the host's SNMP agent"
        echo
        echo "host"
        echo "	hostname or IP address"
        echo
        echo "warning"	
	echo "	warning treshold, in percent"
	echo
	echo "critical"
	echo "	critical treshold, in percent"
	echo
	echo
        echo "Options:"
        echo
        echo "-h, --help"
        echo "	print help"
        echo
        echo "-l, --license"
        echo "	print license info"
        echo
	echo
	echo "Example:"
	echo "	check_snmp_storage_usage public server12 90 95"
	echo
	echo
}

License ()
{
        echo
        echo "check_snmp_storage_usage"
        echo "Copyright (c) 2010 Marko Pavlovic (plugins.from.marko@gmail.com)"
        echo "Version: 1.0"
        echo "Last Modified: September 2010"
        echo
        echo "This program is free software: you can redistribute it and/or modify"
        echo "it under the terms of the GNU General Public License as published by"
        echo "the Free Software Foundation, either version 3 of the License, or"
        echo "(at your option) any later version."
        echo
        echo "This program is distributed in the hope that it will be useful,"
        echo "but WITHOUT ANY WARRANTY; without even the implied warranty of"
        echo "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
        echo "GNU General Public License for more details."
        echo
        echo "You should have received a copy of the GNU General Public License"
        echo "along with this program.  If not, see <http://www.gnu.org/licenses/>."
        echo
}


if [ $# -eq 1 ] && ([ "$1" == "-h" ] || [ "$1" == "--help" ]); then
        Help
        exit "$STATE_OK"
else
        if [ $# -eq 1 ] && ([ "$1" == "-l" ] || [ "$1" == "--license" ]); then
                License
                exit "$STATE_OK"
        else
                if [ $# -ne 4 ]; then
                        Usage
                exit "$STATE_UNKNOWN"
                fi
        fi
fi



warning="false"
critical="false"
outputMessage=""
performanceData=""
#numbers=(`snmpwalk -v2c -c $1 $2 HOST-RESOURCES-MIB::hrStorageType | grep HOST-RESOURCES-TYPES::hrStorageFixedDisk | awk -F " = OID: " '{print $1}' | awk -F "." '{print $2}'`)
numbers=(`snmpwalk -v2c -c $1 $2 HOST-RESOURCES-MIB::hrStorageType | grep HOST-RESOURCES-TYPES::hrStorageNetworkDisk | awk -F " = OID: " '{print $1}' | awk -F "." '{print $2}'`)

let lenght=${#numbers[@]}-1
for i in $(seq 0 $lenght) 
do
	description[i]=$(snmpget -v2c -c $1 $2 HOST-RESOURCES-MIB::hrStorageDescr.${numbers[i]} | awk -F "STRING: " '{print $2}' | awk -F " " '{print $1}' | sed 's/\\//g')
	echo "${description[i]}" | grep "home"  > /dev/null 2>&1
	if [ "$?" -eq "1" ]
	then
		allocationUnits[i]=`snmpget -v2c -c $1 $2 HOST-RESOURCES-MIB::hrStorageAllocationUnits.${numbers[i]} | awk -F "INTEGER: " '{print $2}' | awk -F " Bytes" '{print $1}'`	
		storageSize[i]=`snmpget -v2c -c $1 $2 HOST-RESOURCES-MIB::hrStorageSize.${numbers[i]} | awk -F "INTEGER: " '{print $2}'`
		if [ "${storageSize[i]}" -eq 0 ]; then
			storageSize[i]=1
		fi
		storageSizeGB[i]=$[${allocationUnits[i]}*${storageSize[i]}/1024000]
		storageUsed[i]=`snmpget -v2c -c $1 $2 HOST-RESOURCES-MIB::hrStorageUsed.${numbers[i]} | awk -F "INTEGER: " '{print $2}'`
		storageUsedPercentage[i]=$[${storageUsed[i]}*100/${storageSize[i]}]
		storageUsedGB[i]=$[${storageUsed[i]}*${allocationUnits[i]}/1024000]
		if [ "${storageUsedPercentage[i]}" -ge $4 ]; then
			critical="true"
		else
			if [ "${storageUsedPercentage[i]}" -ge $3 ]; then
				warning="true"
			fi
		fi   
		if [ "$outputMessage" != "" ]; then
			outputMessage="$outputMessage ${description[i]} ${storageUsedPercentage[i]}%" 
		else
			outputMessage="${description[i]} ${storageUsedPercentage[i]}%"
		fi
			
		warnUsed[i]=$[$3*${storageSizeGB[i]}/100]
		critUsed[i]=$[$4*${storageSizeGB[i]}/100]
		if [ "$performanceData" = "" ]; then
       		        performanceData="'${description[i]}'=${storageUsedGB[i]}MB;${warnUsed[i]};${critUsed[i]};0;${storageSizeGB[i]} " 
       		else
               		performanceData="$performanceData'${description[i]}'=${storageUsedGB[i]}MB;${warnUsed[i]};${critUsed[i]};0;${storageSizeGB[i]} "
       		fi
	fi
	
done
if [ "$critical" = "true" ]; then
	echo "Critical $outputMessage|$performanceData"
	#echo -e $outputMessage
	exit $STATE_CRITICAL
else
	if [ "$warning" = "true" ]; then
		echo "Warning $outputMessage|$performanceData"
		#echo -e $outputMessage
		exit $STATE_WARNING
	else
		echo "OK $outputMessage|$performanceData"
		#echo -e $outputMessage
		exit $STATE_OK
	fi
fi	

