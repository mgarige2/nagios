#!/bin/sh  

DELIMITER='|'
EXITCODE="0"
COUNT=0
ERRORCOUNT=0

for FSIDX in `seq $2 2 $3`
do
	ORIGOUTPUT="`/usr/local/nagios/libexec/check_netappfiler.py -H $1 -s fs -f $FSIDX -w $4 -c $5`"
	TEMPOUTPUT="`echo $ORIGOUTPUT | sed 's/nafs_\/vol\///g'`"
	TEMPSTATUS="`echo $TEMPOUTPUT | cut -f1 -d'|'`"
	TEMPPERF="`echo $TEMPOUTPUT | cut -f2 -d'|'`"
	echo $TEMPOUTPUT | grep "UNKNOWN" &> /dev/null
	if [ $? -eq "1" ]
	then
		STATUS="$STATUS $TEMPSTATUS"
		PERF="$PERF $TEMPPERF"
		let COUNT++
	fi
	echo $TEMPOUTPUT | egrep "(CRITICAL|WARNING)" &> /dev/null
	if [ $? -eq "0" ]
	then
		ERRORSTATUS="$ERRORSTATUS $TEMPSTATUS"
		EXITCODE="1"
		let ERRORCOUNT++
	fi
done

echo $STATUS | egrep "(CRITICAL|WARNING)" &> /dev/null
if [ $? -eq "0" ]
then
        echo $STATUS | egrep "CRITICAL" &> /dev/null
        if [ $? -eq "0" ]
        then
                EXITCODE="2"
        fi
	STATUS="$ERRORCOUNT Alerts, $ERRORSTATUS"
else
	STATUS="$COUNT OK"
fi

OUTPUT="$COUNT Volumes Checked, $STATUS $DELIMITER $PERF"

echo $OUTPUT
exit $EXITCODE
