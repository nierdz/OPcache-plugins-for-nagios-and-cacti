#!/bin/bash 
# Get swap used per process
# Not really accurate but useful to get the swap hungry one !

OVERALL=0
for STATUS in /proc/[0-9]*/status
do
	PID=$(echo ${STATUS} | cut -d / -f 3)
	PROGNAME=$(ps -p $PID -o comm --no-headers)
	declare -i SUM=0
	#SUM=$(awk '/Swap/{ sum += $2; mb = sum / 1024 } END { print int( mb ) }' /proc/$PID/smaps 2>/dev/null)

	# This one is more accurate
	SUM=$(awk '/VmSwap:/{ print int( $2 ) }' ${STATUS})
	if (( ${SUM} > 0 )); then
		echo "PID=$PID swapped $(($SUM/1024)) MB ($PROGNAME)"
		OVERALL=$(($OVERALL + $SUM))
	fi
done
echo "Overall swap used: $(($OVERALL/1024)) MB"
