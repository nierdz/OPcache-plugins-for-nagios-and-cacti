#!/bin/bash 
# Get physical memory used per process
# Not really accurate but useful to get the hungry one !
# Written by Kevin MET 2017/07/31

OVERALL=0
for STATUS in /proc/[0-9]*/status
do
	PID=$(echo ${STATUS} | cut -d / -f 3)
	PROGNAME=$(ps -p ${PID} -o comm --no-headers)
	declare -i SUM=0
	SUM=$(awk '/VmRSS:/{ print int( $2 ) }' ${STATUS})
	if (( ${SUM} > 0 )); then
		echo "PID=${PID} physical memory used $((${SUM}/1024)) MB (${PROGNAME})"
	OVERALL=$((${OVERALL} + ${SUM}))
	fi
done
echo "Overall physical memory used: $((${OVERALL}/1024)) MB"
