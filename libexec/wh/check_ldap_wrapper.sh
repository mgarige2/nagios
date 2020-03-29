#!/bin/bash

HOST=$1
WARN=$2
CRIT=$3
PARTNER1=$4
PARTNER2=$5
MASTER=$6

for i in $PARTNER1 $PARTNER2
do
  for j in $(/usr/bin/ldapsearch -x -LLL -H ldap://$HOST:389 -s base -b "dc=reachlocal,dc=com" contextCSN dn: reachlocal,dc=com | grep contextCSN | awk -F'#' '{print $3}')
  do
    if [ "$HOST" != "$i" ]
    then
      NEIGHBORSYNC[$count]="ID $j: $HOST against $i $(/usr/local/nagios/libexec/ldaptoolbox/check_ldap_syncrepl_status.pl -H $HOST -w $WARN -c $CRIT -U ldap://$i:389 -I $j -f | sed "s/deltatime/${j}_${i}/g")"
      EXITCODE[$count]="$?"
      let count++
    fi
    if [ "$j" = "00" ]
    then
      MASTERSYNC[$mastercount]="ID $j: $HOST against master $MASTER $(/usr/local/nagios/libexec/ldaptoolbox/check_ldap_syncrepl_status.pl -H $HOST -w $WARN -c $CRIT -U ldap://$MASTER:389 -I $j -f | sed "s/deltatime/${j}_${MASTER}/g")"
      MASTER_EXITCODE[$mastercount]="$?"
      let mastercount++
    fi
  done
done

k=0
while [ $k -lt $count ]
do
  MESSAGE="$(echo ${NEIGHBORSYNC[$k]} | awk -F'|' '{print $1}' | sed 's/(W:.*)//g') $MESSAGE"
  PERF="$(echo ${NEIGHBORSYNC[$k]} | awk -F'|' '{print $2}' | sed 's/(W:.*)//g') $PERF"
  let k++
done

k=0
while [ $k -lt 1 ]
do
  MESSAGE="$(echo ${MASTERSYNC[$k]} | awk -F'|' '{print $1}' | sed 's/(W:.*)//g') $MESSAGE"
  PERF="$(echo ${MASTERSYNC[$k]} | awk -F'|' '{print $2}' | sed 's/(W:.*)//g') $PERF"
  let k++
done

echo "${EXITCODE[@]} ${MASTER_EXITCODE[@]}" | grep '1' > /dev/null
if [ $? -eq 0 ]
then
  echo "WARNGING, REPLICATION EXCEEDS $WARN seconds ${MESSAGE} | ${PERF}"
  exit 1
fi

echo "${EXITCODE[@]} ${MASTER_EXICODE[@]}" | egrep "[2-9]" > /dev/null
if [ $? -eq 0 ]
then
  echo "CRITICAL, REPLICATION EXCEEDS $CRIT seconds ${MESSAGE} | ${PERF}"
  exit 2
fi

echo "${MESSAGE} | ${PERF}"
exit 0




