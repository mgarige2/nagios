#!/bin/sh

for i in $(echo -e "GET services\nFilter: display_name ~ Inventory\nFilter: plugin_output ~ 10.1\nColumns: host_name" | unixcat /usr/local/nagios/var/rw/live); do /rl/monitoring/nagios/addons/servicenow/inventory_update.sh $i; done
