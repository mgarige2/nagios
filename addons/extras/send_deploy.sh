#!/bin/sh -x

DATACENTER="`hostname | awk -F'.' '{print $2}'`"
NSCACOMMAND="/usr/local/bin/send_nsca -H monitoring.$DATACENTER.reachlocal.com -p 5667 -c /etc/send_nsca.cfg"
SERVERNAME="`hostname | sed 's/.reachlocal.com//g' | sed 's/wh/dyn/g'`"
SERVICENAME="Nagios Deployment Check"

RECENTFILES=$(find /rl/monitoring/nagios/ -name "*.cfg" -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' | egrep "(global|shared|$DATACENTER)" | sort -n | tail -5 | awk '{print $1,$2,$3}')
RECENTNODES=$(find /rl/monitoring/nagios/nodes -name "*" -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' | egrep "($DATACENTER)" | sort -n | tail -5 | awk '{print $1,$2,$3}')

LASTMOD=$(cat ~/lastmod.out)
CURRMOD=$(echo "$RECENTFILES" | tail -1)
LASTNODE=$(cat ~/lastnode.out)
CURRNODE=$(echo "$RECENTNODES" | tail -1)

if [ "$LASTMOD" != "$CURRMOD" -o "$LASTNODE" != "$CURRNODE" ]
then
        RETURNCODE=2
        echo "$CURRMOD" > ~/lastmod.out
        echo "$CURRNODE" > ~/lastnode.out
else
        RETURNCODE=0
fi

if [ $RETURNCODE -eq 2 ]
then
        echo -e "$SERVERNAME\t$SERVICENAME\t$RETURNCODE\tChange Detected ($CURRMOD), Restarting Nagios" | $NSCACOMMAND
        exit 0
else
        echo -e "$SERVERNAME\t$SERVICENAME\t$RETURNCODE\tNo Change Detected (Last Change $CURRMOD)" | $NSCACOMMAND
        exit 1
fi

