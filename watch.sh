#! /bin/bash

# Watch script for junk.sh command. Watches junk directory and notifies of file changes

USAGE="Usage: $0 [DIR]..."
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

handle_trap()
{
	kill $watch_pid
}

# We need to make sure we kill the watch process when we exit
trap handle_trap EXIT

# Handle main command.
if (( $# == 1 ))
then 
	start_watch $1
else
    echo "$USAGE" 1>&2
fi
