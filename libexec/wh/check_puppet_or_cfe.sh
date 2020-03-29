#!/bin/sh -x

HOST=$1
WARN=$2
CRIT=$3

CFRESULT=$(/usr/local/nagios/libexec/check_nrpe -H $HOST -t 30 -c check_file_age_with_args -a '/var/cfengine/cfagent.$(hostname).log' "$WARN" "$CRIT")
CFCODE=$?

echo $CFRESULT | grep "File not found" > /dev/null 2>&1

if [ $? -eq 0 ]
then
	PUPPETRESULT=$(/usr/local/nagios/libexec/check_nrpe -H $HOST -c check_puppet_agent -a $WARN $CRIT)
	#PUPPETRESULT=$(/usr/local/nagios/libexec/check_nrpe -H $HOST -c et_check_procs -a 1:2 1:2 'Ss -a /usr/bin/puppet')
	CODE=$?
	echo "$PUPPETRESULT"
	exit $CODE
else
        if [ $CFCODE -eq 0 ]
        then
                PERF="file_age=$(echo "$CFRESULT" | awk '{print $5}')s"
        fi
        echo "$CFRESULT"
        exit $CFCODE
fi
