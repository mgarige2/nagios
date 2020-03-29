#!/bin/sh 

df_Number=.1.3.6.1.4.1.789.1.5.6.0.
df_FS_Name=.1.3.6.1.4.1.789.1.5.4.1.2.
df_FS_Mounted_On=.1.3.6.1.4.1.789.1.5.4.1.10.
df_FS_kBAvail=.1.3.6.1.4.1.789.1.5.4.1.5.
df_FS_PercentUsed=.1.3.6.1.4.1.789.1.5.4.1.6.
df_FS_INodeUsed=.1.3.6.1.4.1.789.1.5.4.1.7.
df_FS_INodeFree=.1.3.6.1.4.1.789.1.5.4.1.8.
df_FS_PercentINodeUsed=.1.3.6.1.4.1.789.1.5.4.1.9.
df_FS_kBTotal_High=.1.3.6.1.4.1.789.1.5.4.1.14.
df_FS_kBTotal_Low=.1.3.6.1.4.1.789.1.5.4.1.15.
df_FS_kBUsed_High=.1.3.6.1.4.1.789.1.5.4.1.16.
df_FS_kBUsed_Low=.1.3.6.1.4.1.789.1.5.4.1.17.
df_FS_kBAvail_High=.1.3.6.1.4.1.789.1.5.4.1.18.
df_FS_kBAvail_Low=.1.3.6.1.4.1.789.1.5.4.1.19.
df_FS_Status=.1.3.6.1.4.1.789.1.5.4.1.20.
df_FS_Type=.1.3.6.1.4.1.789.1.5.4.1.23.
df64_FS_kBTotal=.1.3.6.1.4.1.789.1.5.4.1.29.
df64_FS_kBUsed=.1.3.6.1.4.1.789.1.5.4.1.30.
df64_FS_kBAvail=.1.3.6.1.4.1.789.1.5.4.1.31.

CRITCOUNT=0
WARNCOUNT=0
TOTCOUNT=0
WARN=$4
CRIT=$5

for i in `seq $2 2 $3` 
do

VOLNAME=`/usr/bin/snmpget -v1 -cr3@chf0r1t -OqevtU $1 $df_FS_Name$i 2> /dev/null | sed 's/\/vol\///g'` 

if [ -z $VOLNAME ]
then
	break	
fi

PERCUSED=`/usr/bin/snmpget -v1 -cr3@chf0r1t -OqevtU $1 $df_FS_PercentUsed$i`
PERCINODES=`/usr/bin/snmpget -v1 -cr3@chf0r1t -Oqevtu $1 $df_FS_PercentINodeUsed$i`
TOTKB=`/usr/bin/snmpget -v1 -cr3@chf0r1t -Oqevtu $1 $df_FS_kBTotal_Low$i`
USEDKB=`/usr/bin/snmpget -v1 -cr3@chf0r1t -Oqevtu $1 $df_FS_kBUsed_Low$i`
AVAILKB=`/usr/bin/snmpget -v1 -cr3@chf0r1t -Oqevtu $1 $df_FS_kBAvail_Low$i`

let TOTCOUNT++
VOLNAME=`echo "${VOLNAME//\"/}"`
GOODSTATUS="$GOODSTATUS $VOLNAME:${PERCUSED}% Used"

if [ "$TOTKB" -lt "0" ]
then
	TOTKB=$(echo "$TOTKB + 2^32" | bc)
fi

if [ "`/usr/bin/snmpget -v1 -cr3@chf0r1t -Oqevtu $1 $df_FS_kBTotal_High$i`" -gt "0" ]
then
	HIGH=`/usr/bin/snmpget -v1 -cr3@chf0r1t -Oqevtu $1 $df_FS_kBTotal_High$i`
	HIGH=`echo "$HIGH + 2^32" | bc`
	TOTKB=$(echo "$TOTKB +$HIGH" | bc)
fi

if [ "$USEDKB" -lt "0" ]
then
	HIGH=`/usr/bin/snmpget -v1 -cr3@chf0r1t -Oqevtu $1 $df_FS_kBUsed_High$i`
	#HIGH=`echo "$HIGH + 2^32" | bc`
	USEDKB=$(echo "$USEDKB + $HIGH + 2^32" | bc)
fi

if [ "$AVAILKB" -lt "0" ]
then
	HIGH=`/usr/bin/snmpget -v1 -cr3@chf0r1t -Oqevtu $1 $df_FS_kBAvail_High$i`
	AVAILKB=$(echo "$AVAILKB + $HIGH + 2^32" | bc)
fi


WARNB=$(echo "$WARN * .01 * $TOTKB * 1024" | bc | awk '{printf "%.0f\n", $1}')
CRITB=$(echo "$CRIT * .01 * $TOTKB * 1024" | bc | awk '{printf "%.0f\n", $1}')
TOTB=$(echo "$TOTKB * 1024" | bc | awk '{printf "%.0f\n", $1}')
USEDB=$(echo "$USEDKB * 1024" | bc | awk '{printf "%.0f\n", $1}')

if [ $USEDB -ge $WARNB -a $USEDB -lt $CRITB ]
then
	let WARNCOUNT++
	VOLSTATUS="$VOLSTATUS WARNING - $VOLNAME: ${PERCUSED}% used (${USEDKB}kB out of ${TOTKB}kB), INodes: ${PERCINODES}% used"

elif [ $USEDB -gt $WARNB -a $USEDB -gt $CRITB -a $TOTB -ne 0 ]
then
	let CRITCOUNT++
	VOLSTATUS="$VOLSTATUS CRITICAL - $VOLNAME: ${PERCUSED}% used (${USEDKB}kB out of ${TOTKB}kB), INodes: ${PERCINODES}% used"
fi

PERFDATA="$PERFDATA $VOLNAME=${USEDB}B;$WARNB;$CRITB;0;$TOTB"

done

ALERTCOUNT=$(($WARNCOUNT + $CRITCOUNT))
STATUS="$TOTCOUNT Volumes Checked"

if [ $ALERTCOUNT -gt 0 ]
then
	STATUS="$STATUS, $ALERTCOUNT Alerts, $VOLSTATUS"
else
	STATUS="$STATUS, $TOTCOUNT OK"
fi

PERFDATA=$(sed -e 's/^[[:space:]]*//' <<< "$PERFDATA")
GOODSTATUS=$(sed -e 's/^[[:space:]]*//' <<< "$GOODSTATUS")

if [ $CRITCOUNT -ge 1 ]
then
    echo -e "$STATUS\n$GOODSTATUS|$PERFDATA"
    exit 2
fi

if [ $WARNCOUNT -ge 1 ]
then
    echo -e "$STATUS\n$GOODSTATUS|$PERFDATA"
    exit 1
fi

echo -e "$STATUS\n$GOODSTATUS|$PERFDATA"
exit 0
