#!/bin/sh

CURRENTHOST=$(hostname | awk -F'.reachlocal.com' '{print $1}')
TOTAL=$(echo -e 'GET services\nFilter: display_name ~ Configuration\nColumns: host_name' | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live | wc -l)
PUPPET=$(echo -e "GET services\nFilter: display_name ~ Configuration\nFilter: plugin_output ~ Puppet\nColumns: host_name" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live | wc -l)
CFE=$(echo -e 'GET services\nFilter: display_name ~ Configuration\nFilter: plugin_output !~ Puppet\nColumns: host_name' | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live | wc -l)

printf "%s\t%s\t%s\t%s\n" "padm022.dyn" "Host Breakdown" "0" "Total: $TOTAL, Puppet: $PUPPET, CFE: $CFE | total=$TOTAL puppet=$PUPPET cfe=$CFE" | /usr/sbin/send_nsca -H localhost -c /etc/send_nsca.cfg

