#! /bin/bash

# Print student name and ID
echo "Student: Alex McBride (S1715224)"

# Constants
USAGE="usage: $0 <fill in correct usage>" 
SIGINT=2
JUNK_DIR_LIMIT=1024 # Bytes
JUNK_DIR=~/.junkdir

# Variables
total_files=0

# Functions
create_junk_dir()
{
	# Create junk directory if does not exist
	if [ ! -d $JUNK_DIR ]
	then
		mkdir $JUNK_DIR
		echo "Created junk directory '$JUNK_DIR'"
	fi
}

junk_files()
{
	# TODO: readable files?
	# Move file to junk directory
	moved_count=0

	for file in $@
	do
		if [ -d $file ]
		then
			echo "Error: can't junk directory '$file'" 1>&2
		elif [ -f $file ]
		then
			dest_path="$JUNK_DIR/$file"
			mv $file $dest_path
			moved_count=$((moved_count+1))
		else
			echo "Error: '$file' does not exist" 1>&2
		fi
	done

	# Output success message
	if [ $moved_count -gt 0 ]
	then
		echo "Junk: $moved_count file(s) moved to junk directory!"
	fi

	# Warn if junk directory size goes over limit
	bytes=$(du -sb $JUNK_DIR | cut -f1)
	if [ $bytes -gt $JUNK_DIR_LIMIT ]
	then
		echo "Warning: junk directory size greater than $JUNK_DIR_LIMIT bytes ($bytes bytes)" 1>&2
	fi
}

list()
{
	# List files in junk dir.
	echo "List of junked files:"
	ls -l $JUNK_DIR
}

recover()
{
	# Move specified file out of junk directory
	source_path="$JUNK_DIR/$1"
	if [ -f $source_path ]
	then
		mv $source_path $1
		echo "File '$1' recovered"
	else
		echo "Error: '$1' does not exist" 1>&2
	fi
}

recover_with_prompt()
{
	# Ask user which file to recover
	echo -n "Enter file to recover: "
	read filename
	recover $filename
}

delete()
{
	# loop through files in junk
	# check if want to delete
	# if yes delete
	# else no
	echo 'Delete'
}

total()
{
	# get junk dir size for all users
	echo 'Total'
}

# Handle SIGINT signal.
trap "echo \"Total junk files: $total_files\"; exit 0" SIGINT

# Make sure junk directory exists.
create_junk_dir

# Handle options.
while getopts :lr:dtwk args #options
do
	case $args in
		l) list;;
		r) recover $OPTARG;;
		d) echo "d option";; 
		t) echo "t option";; 
		w) echo "w option";; 
		k) echo "k option";;     
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
				"delete") echo "d";;
				"total") echo "t";;
				"watch") echo "w";;
				"kill") echo "k";;
				"exit") exit 0;;
				*) echo "unknown option";;
			esac
		done
	fi
else
	junk_files $@
fi


