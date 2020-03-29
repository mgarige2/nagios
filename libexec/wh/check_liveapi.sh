#!/bin/sh -x

EXPRESSION=$1

RECORDED=$(echo -e "GET hosts\nFilter: display_name ~ $EXPRESSION\nColumns: display_name state action_url_expanded\n" | unixcat /usr/local/nagios/var/rw/live)

DNAME=$(echo "$RECORDED" | awk -F';' '{print $1}')
STATE=$(echo "$RECORDED" | awk -F';' '{print $2}')
URL=$(echo "$RECORDED" | awk -F';' '{print $3}')

if [ "$STATE" -eq "0" ]
then
        echo $URL
        echo "Service Up! <IMG SRC='https://monitoring.wh.reachlocal.com$URL'>"
        exit 0
else
        echo "SERVICE DOWN!"
        exit 1
fi

