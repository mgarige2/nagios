#!/bin/bash

hostname=$1;
community=$2;

if [ $# -lt 2 ]; then
  echo "error $0 hostname community_string";
	exit 1;
fi

graph="";
content="";
for ids in $( snmpwalk -v2c -c $community -Oq  $hostname UCD-SNMP-MIB::memory|awk -F"::" '{print $2}'|sed -e "s/\([a-z]\)\.0/\1/g"|sed -e "s/mem//g"|egrep -v "(Index|ErrorName)"|awk -F" " '{print $1"_"$2}');do
	name=${ids%%_*}
	value=${ids##*_}
	if ! [[ "$value" =~ ^[0-9]+$ ]] ; then
		value=0;
	fi
	graph=$graph""$name"="$value"K;;;0 ";
	content=$content""$name":"$value"K ";
done
echo $content"|"$graph
exit 0
