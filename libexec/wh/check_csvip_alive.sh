#!/bin/sh

#laststate0=$(echo -e "GET hosts\nFilter: display_name ~ $_HOSTTARGET0$\nColumns: last_state" | unixcat /usr/local/nagios/var/rw/live)
#laststate1=$(echo -e "GET hosts\nFilter: display_name ~ $_HOSTTARGET1$\nColumns: last_state" | unixcat /usr/local/nagios/var/rw/live)
#laststate2=$(echo -e "GET hosts\nFilter: display_name ~ $_HOSTTARGET2$\nColumns: last_state" | unixcat /usr/local/nagios/var/rw/live)

#echo "$_HOSTTARGET0$ - $laststate0 $_HOSTTARGET1$ - $laststate1 $_HOSTTARGET2$ - $laststate2"
echo "OK"
exit 0
