#!/bin/sh 

HOST=$1
WARN=$2
CRIT=$3


if [ -z $1 ]
then
	echo "must specify a host, ./check_netscaler_cpu.sh <hostname|ipaddress>"
	exit 1
fi

DATA=$(snmpbulkwalk -c r3@chf0r1t  -v 2c $HOST .1.3.6.1.4.1.5951.4.1.1.41.6.1.2 | awk -F':' '{print $NF}' | sed 's/ //g')

mgmtcpu=$(echo "$DATA" | head -n+1)
packetcpu=$(echo "$DATA" | sed '1d')
numpacketcpus=$(echo "$DATA" | wc -l)

perfdata="cpu0=$mgmtcpu%"
output="Mgmt CPU0: $mgmtcpu%"

j=1
sum=0
for i in $(echo "$packetcpu")
do
	perfdata="$perfdata cpu$j=$i%"
	output="$output Packet CPU$j: $i%"
	j=$(($j+1))
	sum=$((sum+$i))
done

averagepacketcpu=$(echo "$sum / $numpacketcpus" | bc)

perfdata="$perfdata cpuavg=$averagepacketcpu%"
output="$output PacketCPU Average: $averagepacketcpu%"

if [ "$WARN" -o "$CRIT" ]
then
	if [ "$averagepacketcpu" -ge "$CRIT" ]
	then
		echo "CRITICAL: $output | $perfdata"
		exit 2
	elif [ "$averagepacketcpu" -ge "$WARN" ]
	then
		echo "WARNING: $output | $perfdata"
		exit 1 
	else
		echo "OK: $output | $perfdata"
		exit 0
	fi
else
	echo "OK: $output | $perfdata"
	exit 0
fi



