#!/bin/sh

echo "${1}" | grep -i "dev" > /dev/null
if [ $? -eq 0 ]
then
	AUTHURL=rlpc-control.dev.wh.reachlocal.com
else
	echo "${1}" | grep -i "qa" > /dev/null
	if [ $? -eq 0 ]
	then
		AUTHURL=rlpc-control.qa.wh.reachlocal.com
	else
		AUTHURL=rlpc-control.stg.wh.reachlocal.com
	fi
fi

USERNAME=nrpe
PASSWORD=Welcome1
HOST=${1}
WHICH_CHECK=${2}

if [ "$WHICH_CHECK" = "vms" ]
then
	RUNNINGVMS=$(/usr/bin/nova --os-username ${USERNAME} --os-password ${PASSWORD} --os-auth-url http://${AUTHURL}:5000/v2.0 --os-tenant-name ${USERNAME} hypervisor-servers ${HOST}.reachlocal.com | grep instance | wc -l)
	VMNAMES="$(/usr/bin/nova --os-username ${USERNAME} --os-password ${PASSWORD} --os-auth-url http://${AUTHURL}:5000/v2.0 --os-tenant-name ${USERNAME} list --host ${HOST}.reachlocal.com --all-tenants 1 | awk '{print $4}' | grep reachlocal | sed ':a;N;$!ba;s/\n/,/g')"
	echo "Hypervisor $HOST is running $RUNNINGVMS VMs: $VMNAMES | vms=$RUNNINGVMS;0;0"
	exit 0
elif [ "$WHICH_CHECK" = "vcpu" ]
then
	TOTAL_VCPUS=$(/usr/bin/nova --os-username ${USERNAME} --os-password ${PASSWORD} --os-auth-url http://${AUTHURL}:5000/v2.0 --os-tenant-name ${USERNAME} hypervisor-show ${HOST}.reachlocal.com | grep "vcpus " | awk '{print $4}')
	USED_VCPUS=$(/usr/bin/nova --os-username ${USERNAME} --os-password ${PASSWORD} --os-auth-url http://${AUTHURL}:5000/v2.0 --os-tenant-name ${USERNAME} hypervisor-show ${HOST}.reachlocal.com | grep "vcpus_" | awk '{print $4}')
	echo "$USED_VCPUS of $TOTAL_VCPUS vCPUs in use | vcpu=$USED_VCPUS;0;0;0;$TOTAL_VCPUS"
	exit 0
elif [ "$WHICH_CHECK" = "freememory" ]
then
	FREE_RAM=$(/usr/bin/nova --os-username ${USERNAME} --os-password ${PASSWORD} --os-auth-url http://${AUTHURL}:5000/v2.0 --os-tenant-name ${USERNAME} hypervisor-show ${HOST}.reachlocal.com | grep "ram" | awk '{print $4}')
	FREE_RAM=$(echo "$FREE_RAM / 1024" | bc)
	echo "Free Memory OK: $FREE_RAM GB | computefreemem=${FREE_RAM}GB;0;0"
	exit 0
elif [ "$WHICH_CHECK" = "usedmemory" ]
then
	USED_RAM=$(/usr/bin/nova --os-username ${USERNAME} --os-password ${PASSWORD} --os-auth-url http://${AUTHURL}:5000/v2.0 --os-tenant-name ${USERNAME} hypervisor-show ${HOST}.reachlocal.com | grep "memory_mb_used" | awk '{print $4}')
	USED_RAM=$(echo "$USED_RAM / 1024" | bc)
	echo "Used Memory OK: $USED_RAM GB | computeusedmem=${USED_RAM}GB;0;0"
	exit 0
elif [ "$WHICH_CHECK" = "totalmemory" ]
then
	TOTAL_RAM=$(/usr/bin/nova --os-username ${USERNAME} --os-password ${PASSWORD} --os-auth-url http://${AUTHURL}:5000/v2.0 --os-tenant-name ${USERNAME} hypervisor-show ${HOST}.reachlocal.com | grep "memory_mb " | awk '{print $4}')
	TOTAL_RAM=$(echo "$TOTAL_RAM / 1024" | bc)
	echo "Total Memory OK: $TOTAL_RAM GB | computetotalmem=${TOTAL_RAM}GB;0;0"
	exit 0
elif [ "$WHICH_CHECK" = "mempct" ]
then
	USED_RAM=$(/usr/bin/nova --os-username ${USERNAME} --os-password ${PASSWORD} --os-auth-url http://${AUTHURL}:5000/v2.0 --os-tenant-name ${USERNAME} hypervisor-show ${HOST}.reachlocal.com | grep "memory_mb_used" | awk '{print $4}')
        TOTAL_RAM=$(/usr/bin/nova --os-username ${USERNAME} --os-password ${PASSWORD} --os-auth-url http://${AUTHURL}:5000/v2.0 --os-tenant-name ${USERNAME} hypervisor-show ${HOST}.reachlocal.com | grep "memory_mb " | awk '{print $4}')
	USED_PERCENT=$(echo "scale=2;$USED_RAM / $TOTAL_RAM" | bc)
	USED_PERCENT=$(echo "scale=0;$USED_PERCENT * 100" | bc | awk '{printf("%d\n",$1 + 0.5)}')
	echo "Memory Usage OK: ${USED_PERCENT}% | computemempct=${USED_PERCENT}%;0;0"
	exit 0
fi

exit 0
