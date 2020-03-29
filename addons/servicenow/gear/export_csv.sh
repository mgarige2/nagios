#!/bin/sh

rm -f /tmp/deviceinventory.csv
mysql -uroot -pnagios -e"use inventory; select * from deviceinventory into outfile '/tmp/deviceinventory.csv' fields terminated by ',' lines terminated by '\n'"
sed -i '1i\u_name,u_address,u_manufacturer,u_model,u_datacenter' /tmp/deviceinventory.csv

