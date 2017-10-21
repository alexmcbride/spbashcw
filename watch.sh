#! /bin/bash

# Watch script for junk.sh command. Watches junk directory and notifies of file changes

USAGE="Usage: $0 [DIR]... [OPTION]..."
watch_pid=

start_watch()
{
	# TODO: check if already watch script running for this directory?	
	# Starts watching specified directory
	echo "Watching junk directory '$1'"
	watch -n 15 ls $1 &
	watch_pid=$! # Save PID so we can kill it later

	# Stop script from exiting
	while true
	do
		sleep 1
	done	
}

stop_watch()
{
	# Stops any running watch scripts.
	pids=($(ps -ef | awk '/[w]atch.sh/{print $2}'))
	if [ ${#pids[@]} -eq 0 ]
	then
		for pid in $pids
		do
			echo "Stopping watch.sh script (PID: $pid)"
			kill $pid
		done
	else
		echo "Error: no watch scripts to kill" 1>&2
	fi
}

# We need to make sure we kill the watch process when we exit
trap "kill $watch_pid;" EXIT
trap "echo \"Stopping watch script\"; exit 1;" SIGINT # Only show message on SIGINT

# Handle options.
while getopts :k args
do
	case $args in
		k) stop_watch;;
		\?) echo "$USAGE" 1>&2;;
	esac
done

# Remove options.
((pos = OPTIND - 1))
shift $pos

# Handle main command.
if (( $# == 1 ))
then 
	start_watch $1
else
    echo "$USAGE" 1>&2
fi
