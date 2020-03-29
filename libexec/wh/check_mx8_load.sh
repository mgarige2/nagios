#!/bin/sh

LIBEXEC=/usr/local/nagios/libexec
OUTPUT=""
PERF=""


TEMP=`$LIBEXEC/check_snmp -H 10.10.19.70 -o .1.3.6.1.4.1.14525.4.8.1.1.11.1.0 -w 90 -c 99 -C r3@chf0r1t -l "LOADINSTANT" -P 2c`
OUTPUT="$OUTPUT `echo $TEMP | awk -F'|' '{print $1}'`"
PERF="$PERF `echo $TEMP | awk -F '|' '{print $2}'`"
TEMP=`$LIBEXEC/check_snmp -H 10.10.19.70 -o .1.3.6.1.4.1.14525.4.8.1.1.11.2.0 -w 90 -c 99 -C r3@chf0r1t -l  "1MINLOAD" -P 2c`
OUTPUT="$OUTPUT `echo $TEMP | awk -F'|' '{print $1}' | sed 's/SNMP OK//g'`"
PERF="$PERF `echo $TEMP | awk -F '|' '{print $2}'`"
TEMP=`$LIBEXEC/check_snmp -H 10.10.19.70 -o .1.3.6.1.4.1.14525.4.8.1.1.11.3.0 -w 90 -c 99 -C r3@chf0r1t -l  "5MINLOAD" -P 2c`
OUTPUT="$OUTPUT `echo $TEMP | awk -F'|' '{print $1}' | sed 's/SNMP OK//g'`"
PERF="$PERF `echo $TEMP | awk -F '|' '{print $2}'`"
TEMP=`$LIBEXEC/check_snmp -H 10.10.19.70 -o .1.3.6.1.4.1.14525.4.8.1.1.11.4.0 -w 90 -c 99 -C r3@chf0r1t -l "60MINLOAD" -P 2c`
OUTPUT="$OUTPUT `echo $TEMP | awk -F'|' '{print $1}' | sed 's/SNMP OK -//g'`"
PERF="$PERF `echo $TEMP | awk -F '|' '{print $2}'`"


echo "$OUTPUT|$PERF"
