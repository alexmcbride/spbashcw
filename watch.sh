#! /bin/bash
# Bash Coursework - script for watch command
# Author: Alex McBride
# Student ID: S1715224
# Student Email: AMCBRI206@caledonian.ac.uk
# Date: 22/10/2017

# Watch script for junk.sh. Starts and stops watch command.

USAGE="Usage: $0 [DIR]... [-k]"
watch_pid=

start_watch()
{
	# Starts watching specified directory
	echo "Watching junk directory '$1'"
	watch -n 15 ls $1 &
	watch_pid=$! # Save PID so we can kill it later

	# Keep process running
	while true
	do
		sleep 1
	done	
}

stop_watch()
{
	# Stops any running watch scripts.
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

handle_trap()
{
	# Make sure watch process is always killed when we exited
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

