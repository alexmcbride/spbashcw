#! /bin/bash

USAGE="Usage: $0 [dir] | [-k]"
watch_pid=

start_watch()
{
	watch -n 15 ls $1 &
	watch_pid=$!

	while true
	do
		sleep 1
	done	
}

stop_watch()
{
	pids=($(ps -ef | awk '/[w]atch.sh/{print $2}'))
	for pid in $pids
	do
		if [[ $pid -ne $$ ]]
		then
			echo "Stopping watch.sh script (PID: $pid)"
			kill $pid
		fi
	done
}

handle_trap()
{
	if [[ -n $watch_pid ]]
	then
		kill $watch_pid
	fi
}

trap handle_trap EXIT

while getopts :k args
do
	case $args in
		k)  stop_watch
			exit 0
			;;
	   \?) echo "unknown option: -$OPTARG" 1>&2;;
	esac
done		

((pos = OPTIND - 1))
shift $pos 

if (( $# == 1 ))
then 
	start_watch $1
else
    echo "$USAGE" 1>&2
fi

