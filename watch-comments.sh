#!/bin/bash
#
UPDATE_SECONDS=15
USAGE="Usage: $0 [dir] | [-k]"

# Hash table to store files and their hashes
declare -A file_map

# Create an hash sum of the specified file.
create_hash()
{
	# SHA1 more robust than MD5
	echo $(sha1sum $1 | cut -d' ' -f1)
}

# Check for changes to directory
check_directory()
{
	files=$(ls $1)
	for file in $files; do
		# If file in map then check hash sum, otherwise add to map
		if [ ${file_map[$file]+_} ]; then
			old_hash=${file_map[$file]}
			new_hash=$(create_hash "$1/$file")
			if [ $old_hash == $new_hash ]; then
				# Hashes still match, all is well.
				echo "$file (unchanged)"
			else
				# Hash different, file has changed.
				echo "$file (updated)"
				file_map[$file]=$new_hash
			fi
		else
			echo "$file (added)"
			file_map[$file]=$(create_hash "$1/$file")
		fi
	done

	# Remove any files from map that are no longer in directory
	for i in "${!file_map[@]}"
	do
		found=1
		for file in $files; do
			if [ $file == $i ]; then
				found=0
			fi
		done

		if [ $found -eq 1 ]; then
	  		unset file_map[$i]
	  		echo "$file (removed)"
		fi
	done

	echo "---- Updates every $UPDATE_SECONDS seconds ----"
}

# Loop and check directory every interval
start_watch()
{
	while true; do
		check_directory $1

		sleep $UPDATE_SECONDS
	done
}

# Stop all instances of this script.
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
