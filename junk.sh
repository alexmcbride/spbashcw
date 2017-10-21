#! /bin/bash

# Bash Coursework - script for junk command
# Author: Alex McBride
# Student ID: S1715224
# Student Email: AMCBRI206@caledonian.ac.uk
# Date: 19/10/2017

# Print student name and ID
echo "Student: Alex McBride (S1715224)"

# Constants
USAGE="usage: $0 <fill in correct usage>" 
SIGINT=2
JUNK_DIR_LIMIT=1024 # Bytes
JUNK_DIR_NAME=.junkdir
JUNK_DIR=~/$JUNK_DIR_NAME

# Functions
create_junk_dir()
{
	# Create junk directory if does not exist
	if [ ! -d $JUNK_DIR ]
	then
		if mkdir $JUNK_DIR
		then
			echo "Created junk directory '$JUNK_DIR'"
		else
			exit 1 # No point continuing if cannot create this...
		fi
	fi
}

move_file()
{
	# Performs various checks before attempting to move specified file.
	# Returns boolean indicating if move was successful.
	if [ ! -f $1 ]
	then
		echo "Error: source file '$1' does not exist" 1>&2
	elif [ -d $1 ]
	then
		echo "Error: '$1' is a directory" 1>&2
	elif [ -f $2 ]
	then
		echo "Error: destination file '$2' already exists" 1>&2
	elif [ ! -r $1 ]
	then
		echo "Error: source file '$1' is not readable" 1>&2
	else
		return $(mv $1 $2)
	fi
	return 1
}

get_dir_size()
{
	# Gets size of specified directory in bytes
	echo $(du -sb $1 | cut -f1)
}

check_junk_dir_size()
{
	# Warn if junk directory size goes over limit
	bytes=$(get_dir_size $JUNK_DIR)
	if [ $bytes -gt $JUNK_DIR_LIMIT ]
	then
		echo "Warning: junk directory size greater than $JUNK_DIR_LIMIT bytes ($bytes bytes)" 1>&2
	fi
}

junk_files()
{
	moved_count=0

	# Move specified files to junk directory and increment counter.
	for file in $@
	do
		dest_path=$JUNK_DIR/$file
		if move_file $file $dest_path
		then
			moved_count=$((moved_count+1))
		fi		
	done

	# Output success message
	if [ $moved_count -gt 0 ]
	then
		echo "Junk: $moved_count file(s) moved to junk directory!"
		check_junk_dir_size	
	fi
}

count_files()
{
	# Counts files in the specified directory, if it exists.
	if [ -d $1 ]
	then
		echo $(($(ls -l $1 | wc -l) -1))
	else
		echo "0"
	fi
}

count_junk_files()
{
	# Gets number of files in junk directory
	echo $(count_files $JUNK_DIR)
}

list()
{
	# Lists files in junk dir.
	count=$(count_junk_files)
	echo "Junk directory list: $count file(s)"
	if [ $count -gt 0 ]
	then
		echo "Name          Bytes          Type"
		echo "----          -----          ----"
		for file in $JUNK_DIR/*
		do
			size=$(du $file -b | cut -f1)
			name=$(basename $file)
			filetype=$(file $file | cut -d':' -f2)
			printf "%-12s  %-12s  %-12s\n" "$name" "$size" "$filetype"
		done
	fi
}

recover()
{
	# TODO: multiple files in single command?
	# Recovers specified file from junk directory
	source_path="$JUNK_DIR/$1"
	if move_file $source_path $1
	then
		echo "File '$1' recovered"
	fi
}

recover_with_prompt()
{
	# Ask user which file to recover, only show if actually files in junk dir.
	total_files=$(count_junk_files)
	if [ $total_files -gt 0 ]
	then
		echo -n "Enter file to recover: "
		read filename
		recover $filename
	else
		echo "Recover junk directory - $total_files file(s)" 1>&2
	fi
}

delete()
{
	# Interactively delete files in junk directory
	# TODO: specify files in optargs?
	total_files=$(count_junk_files)
	echo "Delete junk directory - $total_files file(s)"
	if [ $total_files -gt 0 ]
	then
		files=($(ls $JUNK_DIR))
		count=0
		deleted_count=0	
		
		# Loop through each file and ask if user wants to delete it.
		while [ $count -lt $total_files ]
		do
			filename=${files[$count]}
			echo -n "Delete file '$filename'? (y/n): "
			read choice
			case $choice in
				[yY] | [yY][Ee][Ss] )
					rm $JUNK_DIR/$filename
					count=$(($count+1))
					deleted_count=$(($deleted_count+1))
				;;
				[nN] | [n|N][O|o] )
					count=$(($count+1))
				;;
				*) echo "Invalid input" 1>&2
			esac
		done

		# Output success message.
		if [ $deleted_count -gt 0 ]
		then
			echo "Deleted $deleted_count file(s)"
		fi
	fi
}

total()
{
	# get junk dir size for all users
	user_list=$(cut -d: -f1 /etc/passwd)
	total_size=0

	# Loop through each user and try and get the size of their junk directory.
	for user in $user_list
	do
		user_junkdir=/home/$user/$JUNK_DIR_NAME
		# Check junk dir exists and is readble.
		if [ -d $user_junkdir ] && [ -r $user_junkdir ]
		then
			size=$(get_dir_size $user_junkdir)
			total_size=$(($total_size+$size))
			#echo "$user $size bytes"
		fi		
	done

	# Output message.
	echo "Total junk directory size for all users: $total_size bytes"
}

start_watch()
{
	# Starts the watch script.
	./watch.sh $JUNK_DIR
}

kill_watch()
{
	# Tell the watch script to kill itself
	./watch.sh -k
}

handle_trap()
{
	# Output total file count and then exit.
	echo "Total junk files: $(count_junk_files)"
	echo "Exiting..."
	exit 1
}

# Handle SIGINT signal.
trap handle_trap SIGINT

# Make sure junk directory exists.
create_junk_dir

# Handle options.
while getopts :lr:dtwk args #options
do
	case $args in
		l) list;;
		r) recover $OPTARG;;
		d) delete $OPTARG;; 
		t) total;; 
		w) start_watch;; 
		k) kill_watch;;     
		:) echo "data missing, option -$OPTARG";;
		\?) echo "$USAGE";;
	esac
done

# Remove processed options from args.
((pos = OPTIND - 1))
shift $pos

# Handle main menu.
PS3='option> '
if (( $# == 0 ))
then 
	if (( $OPTIND == 1 )) 
	then 
		select menu_list in list recover delete total watch kill exit
		do 
			case $menu_list in
				"list") list;;
				"recover") recover_with_prompt;;
				"delete") delete;;
				"total") total;;
				"watch") start_watch;;
				"kill") kill_watch;;
				"exit") exit 0;;
				*) echo "unknown option";;
			esac
		done
	fi
else
	# Handle junk command.
	junk_files $@
fi
