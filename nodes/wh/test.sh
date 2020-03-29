#!/bin/bash

for i in `cat old.txt`
do
val=$(egrep -ir "$i" *.cfg | grep host_name |awk '{print $1}'|cut -d':' -f1)

val1=$(egrep -ir "$i" *.cfg | grep host_name |awk '{print $3}'|cut -d':' -f1)

val2=$(cat host.txt| grep "$i")


sed -i "s/$val1/$val2/g" $val

done
