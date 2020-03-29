#!/bin/sh

INPUT=$1

if [ -z $1 ] 
then
	/rl/monitoring/nagios/addons/servicenow/update_servicenow.pl --url="https://reachlocal.service-now.com/sys_import.do?sysparm_import_set_tablename=u_datacenter_import&sysparm_transform_after_load=true" --uploadfile=$INPUT
else
	/rl/monitoring/nagios/addons/servicenow/update_servicenow.pl --url="https://reachlocal.service-now.com/sys_import.do?sysparm_import_set_tablename=u_datacenter_import&sysparm_transform_after_load=true" --uploadfile=/tmp/inventory.csv
fi
