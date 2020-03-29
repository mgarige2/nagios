#!/bin/sh

rm -f /tmp/inventory.csv
mysql -uroot -pnagios -e"use inventory; select * from inventory into outfile '/tmp/inventory.csv' fields terminated by ',' lines terminated by '\n'"
sed -i '1i\u_hosname,u_ipaddress,u_modelnumber,u_serialnumber,u_isvm,u_os,u_memory,u_datacenter' /tmp/inventory.csv
