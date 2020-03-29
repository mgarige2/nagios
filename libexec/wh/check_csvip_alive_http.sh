#!/bin/sh

output=$(curl http://$1/$2 -k)
echo "$output" | egrep -i "(404|Unavailable)" > /dev/null 2>&1
error=$?

$perfdata=$(/usr/local/nagios/libexec/check_http -I $1 --ssl -f ok -e 'HTTP/1.' -w 2 -c 5 | awk -F'|' '{print $2}')

if [ $error -eq 0 ]
then
        echo "HEALTH CHECK FAILED: http://$1/$2 returned an error: $output | $perfdata"
        exit 2
else
        echo "Health Check OK: http://$1/$2 returned valid data $output | $perfdata"
        exit 0
fi

