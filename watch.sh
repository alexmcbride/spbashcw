#! /bin/bash

# Watch script for junk.sh command. Watches junk directory and notifies of file changes

USAGE="Usage: $0 [dir]"
watch_pid=

handle_trap()
{
	echo "Stopping watch junk directory"
	kill $watch_pid
}

# We need to make sure we kill the watch process when we exit
trap handle_trap EXIT

# Show usage if no arguments passed
if [ $# -eq 0 ]
then
    echo "$USAGE" 1>&2
    exit 1
fi

echo "Watching junk directory '$1'"

# Start watch process in background
watch -n 15 ls $1 &

# Save PID of watch process so we can kill it later
watch_pid=$!
 
# Stop script from exiting
while true
do
	sleep 1
done
