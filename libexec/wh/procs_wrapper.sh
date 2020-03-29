#!/bin/sh -x

result=$(./check_procs) 

exitcode="$?"

echo $result

resultvalue=$(echo "$result" | awk '{print $3}')

echo "$result | PROCS='$resultvalue'"

exit $exitcode
