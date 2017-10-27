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
	echo "---- Update $(date +%H:%M:%S) ----"	

	files=$(ls $1)
	for file in $files; do
		full_path="$1/$file"
		if [ -f $full_path ]; then
			if [ ${file_map[$file]+_} ]; then
				old_hash=${file_map[$file]}
				new_hash=$(create_hash $full_path)
				
				if [ $old_hash == $new_hash ]; then
					echo "- $file (unmodified)"
				else
					echo "- $file (modified)"
					file_map[$file]=$new_hash
				fi
			else
				echo "- $file (added)"
				file_map[$file]=$(create_hash $full_path)
			fi
		fi
	done

	for i in "${!file_map[@]}"
	do
		found=1
		for file in $files; do
			if [ -f "$1/$file" ] && [ $file == $i ]; then
				found=0
				break
			fi
		done

		if [ $found -eq 1 ]; then
	  		unset file_map[$i]
	  		echo "- $i (removed)"
		fi
	done
}

start_watch()
{
	echo "Watching '$1' every $UPDATE_SECONDS seconds..."
	while true; do
		check_directory $1

		sleep $UPDATE_SECONDS
	done
}

stop_watch()
{
	pids=($(ps -ef | awk '/[w]atch.sh/{print $2}'))
	for pid in $pids; do
		if [[ $pid -ne $$ ]]; then
			echo "Stopping watch.sh script (PID: $pid)"
			kill $pid
		fi
	done
}

while getopts :k args; do
	case $args in
		k)  stop_watch
			exit 0
			;;
	   \?) echo "unknown option: -$OPTARG" 1>&2;;
	esac
done		

((pos = OPTIND - 1))
shift $pos 

if (( $# == 1 )); then 
	start_watch $1
else
    echo "$USAGE" 1>&2
fi
