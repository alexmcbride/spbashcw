#! /bin/bash
#
# Bash Coursework - script for watch command
# Author: Alex McBride
# Student ID: S1715224
# Student Email: AMCBRI206@caledonian.ac.uk
# Date: 22/10/2017

USAGE="Usage: $0 [dir] | [-k]"
watch_pid=

# Starts watching specified directory
start_watch()
{
	watch -n 15 ls $1 &
	watch_pid=$! # Save PID so we can kill it later

	# Keep process running
	while true
	do
		sleep 1
	done	
}

# Stops any running watch scripts.
stop_watch()
{
	pids=($(ps -ef | awk '/[w]atch.sh/{print $2}'))
	for pid in $pids
	do
		# Ignore this script.
		if [[ $pid -ne $$ ]]
		then
			# Stop script
			echo "Stopping watch.sh script (PID: $pid)"
			kill $pid
		fi
	done
}

# Make sure watch process is always killed when we exited
handle_trap()
{
	if [[ -n $watch_pid ]]
	then
		kill $watch_pid
	fi
}

trap handle_trap EXIT

# Handle options
while getopts :k args
do
	case $args in
		k)  stop_watch
			exit 0
			;;
	   \?) echo "unknown option: -$OPTARG" 1>&2;;
	esac
done		

# Removed processed options
((pos = OPTIND - 1))
shift $pos 

# Handle main command
if (( $# == 1 ))
then 
	start_watch $1
else
    echo "$USAGE" 1>&2
fi

