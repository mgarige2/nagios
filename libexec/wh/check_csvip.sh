#!/bin/sh

total=0
echo "$1" | egrep "[a-z]" > /dev/null 2>&1
if [ $? -eq 0 ]
then
	laststateone=$(echo -e "GET hosts\nFilter: display_name ~ ${1}\nColumns: display_name last_state" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live)
	if [ $laststateone ] 
	then
		let total++
	fi
fi

echo "$2" | egrep "[a-z]" > /dev/null 2>&1
if [ $? -eq 0 ]
then
        laststatetwo=$(echo -e "GET hosts\nFilter: display_name ~ ${2}\nColumns: display_name last_state" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live)
        if [ $laststatetwo ]
        then
                let total++
        fi
fi

echo "$3" | egrep "[a-z]" > /dev/null 2>&1
if [ $? -eq 0 ]
then
        laststatethree=$(echo -e "GET hosts\nFilter: display_name ~ ${3}\nColumns: display_name last_state" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live)
        if [ $laststatethree ]
        then
                let total++
        fi
fi

echo "$4" | egrep "[a-z]" > /dev/null 2>&1
if [ $? -eq 0 ]
then
        laststatefour=$(echo -e "GET hosts\nFilter: display_name ~ ${4}\nColumns: display_name last_state" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live)
        if [ $laststatefour ]
        then
                let total++
        fi
fi

echo "$5" | egrep "[a-z]" > /dev/null 2>&1
if [ $? -eq 0 ]
then
        laststatefive=$(echo -e "GET hosts\nFilter: display_name ~ ${5}\nColumns: display_name last_state" | /usr/local/bin/unixcat /usr/local/nagios/var/rw/live)
        if [ $laststatefive ]
        then
                let total++
        fi
fi

count=$(echo -e "$laststateone, $laststatetwo, $laststatethree, $laststatefour, $laststatefive" | egrep -o ";[0]" | wc -l)
echo -e "$laststateone, $laststatetwo, $laststatethree, $laststatefour, $laststatefive" | grep ";1" > /dev/null 2>&1
error=$?
if [ $error -eq 0 ]
then
        output=$(echo -e "$laststateone, $laststatetwo, $laststatethree, $laststatefour, $laststatefive" | sed -e "s/;[1-9]/;DOWN/g" | sed 's/;0/;UP/g')
	echo "$output | services=$count"
else
        output=$(echo -e "$laststateone, $laststatetwo, $laststatethree, $laststatefour, $laststatefive" | sed 's/;0/;UP/g')
	echo "$output | services=$count"
fi

if [ $(expr $total - $count) -eq 0 ]
then
	exit 0
elif [ $(expr $total - $count) -le 2 ]
then
	exit 1
else 
	exit 2
fi
