#!/bin/sh

for i in $(echo -e "GET services\nFilter: host_name ~ xen\nFilter: display_name ~ VM Check\nColumns: host_name" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live)
do
for j in $(echo -e "GET services\nFilter: host_name ~ $i\nFilter: display_name ~ VM Check\nColumns: plugin_output" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live | awk -F':' '{print $3}')
do
if [[ $j != "" ]]
then
temp=$(echo -e "GET hosts\nFilter: display_name ~ $j\.(wh|local|dev|)$\nColumns: display_name" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live | awk '{print $1}')
if [[ $temp == "" ]]
then
temp=$(echo -e "GET hosts\nFilter: display_name ~ $j\.dyn$\nColumns: display_name" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live | awk '{print $1}')
fi
printf "%s\t%s\t%s\t%s\n" "$temp" "Which Dom0" "0" "$i" | /usr/sbin/send_nsca -H monitoring.wh.reachlocal.com -c /etc/send_nsca.cfg
fi
done
done

