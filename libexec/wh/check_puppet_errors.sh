#!/bin/bash

WARN=$1
CRIT=$2

TOTAL=$(echo -e "GET services\nFilter: display_name ~ Configuration Management\nFilter: plugin_output ~ Puppet\nStats: state < 4" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live)
NUMCRIT=$(echo -e "GET services\nFilter: display_name ~ Configuration Management\nFilter: plugin_output ~ Puppet\nStats: state != 0" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live)

TEMP=$(echo "scale=2;$NUMCRIT/$TOTAL" | bc)
PERCENT=$(echo "$TEMP * 100" | bc | awk -F'.' '{print $1}')
TEMP=$(echo "scale=2;$WARN/100" | bc)
WNUM=$(echo "$TEMP * $TOTAL" | bc | awk '{printf("%d\n",$1 + 0.5)}') 
TEMP=$(echo "scale=2;$CRIT/100" | bc)
CNUM=$(echo "$TEMP * $TOTAL" | bc | awk '{printf("%d\n",$1 + 0.5)}')

if [ -z "$TOTAL" ]
then
  PERCENT=0
  TOTAL=0
  NUMCRIT=0
fi

RESULT="${PERCENT}% of hosts have Puppet errors (${NUMCRIT} out of ${TOTAL} total)"
PERFDATA="errors=${NUMCRIT};${WNUM};${CNUM};0;${TOTAL}"

if [ $CNUM -gt 0 -o $WNUM -gt 0 ]
then
  RESULT="$RESULT - $(echo -e "GET services\nFilter: display_name ~ Configuration Management\nFilter: plugin_output ~ Puppet\nFilter: state != 0\nColumns: host_name" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live |  tr "\n" "," | sed -e "s/,$//g")"
fi

if [ $PERCENT -ge $CRIT ]
then
  STATUS="CRITICAL:"
  EXITCODE=2
elif [ $PERCENT -ge $WARN ]
then
  STATUS="WARNING:"
  EXITCODE=1
else
  STATUS="OK:"
  EXITCODE=0
fi

echo "$STATUS $RESULT | $PERFDATA"
exit $EXITCODE
