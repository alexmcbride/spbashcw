#!/bin/bash
#
UPDATE_SECONDS=15
USAGE="Usage: $0 [dir] | [-k]"

# Hash table to store files and their hashes
declare -A file_map
# Starts watching specified directory
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
				echo "No change to '$file'"
			else
				# Hash different, file has changed.
				echo "Updated '$file'"
				file_map[$file]=$new_hash
			fi
		else
			echo "Added '$file'"
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
	  		echo "Removed file '$i'"
		fi
	done

	# Columns with A/R/M/X column notes

	echo "---- Updates every $UPDATE_SECONDS seconds ----"
}

start_watch()
{
	# Check directory every interval
	while true; do
		check_directory $1

		sleep $UPDATE_SECONDS
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
