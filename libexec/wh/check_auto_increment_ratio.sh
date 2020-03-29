#!/bin/bash
HOST=$1
USER=$2
PASS=$3

# Check for a warning condition: auto increment ration between 90% and 98.99%
WARN=$(mysql -h ${HOST} -u ${USER} -p${PASS} -N -e "select TABLE_SCHEMA,TABLE_NAME,COLUMN_NAME,auto_increment_ratio from common_schema.auto_increment_columns where auto_increment_ratio between .9000 and .9899")

# Check for a ctritical condition: auto incrmement ration 99% or greater
CRIT=$(mysql -h ${HOST} -u ${USER} -p${PASS} -N -e "select TABLE_SCHEMA,TABLE_NAME,COLUMN_NAME,auto_increment_ratio from common_schema.auto_increment_columns where auto_increment_ratio > .9899")


# If there is nothing to report, exit with rc=0
if [ $((${#WARN}+${#CRIT})) -eq 0 ] ; then
    OUTPUT=$(mysql -h ${HOST} -u ${USER} -p${PASS} -N -e "select TABLE_SCHEMA,TABLE_NAME,COLUMN_NAME,auto_increment_ratio from common_schema.auto_increment_columns order by auto_increment_ratio desc limit 3;")
    echo "OK ${OUTPUT}" | sed 's/[0-9] /; /g'
    exit 0
fi

# If there is a crtitical issue (which has higher priority than a warning) emit the table information
# and exit with rc=2
if [ ${#CRIT} -gt 0 ] ; then
    echo "CRITICAL ${CRIT}" | sed 's/[0-9] /; /g'
    exit 2
fi

# There was a warning but it's not critical so emit the table information and exit with rc=1
echo "WARNING ${WARN}" | sed 's/[0-9] /; /g'
exit 1

