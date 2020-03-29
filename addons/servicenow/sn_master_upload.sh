#!/bin/sh

/rl/monitoring/nagios/addons/servicenow/db_import.sh
/rl/monitoring/nagios/addons/servicenow/export_csv.sh

IMPORTSIZE=$(cat /tmp/inventory.csv | wc -l)

if [ $IMPORTSIZE -gt 150 ]
then
	cd /tmp
	split -l 100 -d /tmp/inventory.csv inventory_z
	HEADERS=$(cat /tmp/inventory.csv | head -n+1)
	for i in $(ls -alh | grep inventory_z | awk '{print $9}')
	do
		sed -i "/1i\\$HEADERS" $i
		/rl/monitoring/nagios/addons/servicenow/bulk_update.sh $i
		rm $i
	done
else
	/rl/monitoring/nagios/addons/servicenow/bulk_update.sh
fi

