#!/bin/bash

UPDATE_SECONDS=15
USAGE="Usage: $0 [dir] | [-k]"

declare -A file_map

create_hash()
{
	echo $(sha1sum $1 | cut -d' ' -f1)
}

check_directory()
{
	files=$(ls $1)
	for file in $files; do
		if [ ${file_map[$file]+_} ]; then
			old_hash=${file_map[$file]}
			new_hash=$(create_hash "$1/$file")
			if [ $old_hash == $new_hash ]; then
				echo "$file (unchanged)"
			else
				echo "$file (updated)"
				file_map[$file]=$new_hash
			fi
		else
			echo "$file (added)"
			file_map[$file]=$(create_hash "$1/$file")
		fi
	done

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

start_watch()
{
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
