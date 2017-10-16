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
		if mkdir $JUNK_DIR
		then
			echo "Created junk directory '$JUNK_DIR'"
		else
			exit 1
		fi
	fi
}

move_file()
{
	# Performs various checks and then moves a file.
	# Returns boolean indicating if move was successful.
	if [ ! -f $1 ]
	then
		echo "Error: source file '$1' does not exist" 1>&2
	elif [ -d $1 ]
	then
		echo "Error: source '$1' is directory" 1>&2
	elif [ -f $2 ]
	then
		echo "Error: junked file '$2' already exists" 1>&2
	elif [ ! -r $1 ]
	then
		echo "Error: source file '$1' is not readable" 1>&2
	else
		return $(mv $1 $2)
	fi
	return 1
}

check_junk_dir_size()
{
	# Warn if junk directory size goes over limit
	bytes=$(du -sb $JUNK_DIR | cut -f1)
	if [ $bytes -gt $JUNK_DIR_LIMIT ]
	then
		echo "Warning: junk directory size greater than $JUNK_DIR_LIMIT bytes ($bytes bytes)" 1>&2
	fi
}

junk_files()
{
	# Move file to junk directory
	moved_count=0
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
	fi

	check_junk_dir_size
}

list()
{
	# List files in junk dir.
	files=$(ls $JUNK_DIR | cut -f1)
	echo "Junk directory list:"
	echo "================================================"
	printf "|  %12s  |  %8s  |  %12s  |\n" "NAME" "BYTES" "TYPE"
	echo "================================================"
	for file in $files
	do
		path=$JUNK_DIR/$file
		size=$(du $path -b | cut -f1)
		name=$(basename $path)
		_type=$(file $path | cut -d':' -f2)
		printf "|  %12s  |  %8s  |  %12s  |\n" "$name" "$size" "$_type"
	done
	echo "================================================"
}

recover()
{
	# Move specified file out of junk directory
	source_path="$JUNK_DIR/$1"
	if move_file $source_path $1
	then
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
		d) delete;; 
		t) total;; 
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
				"delete") delete;;
				"total") total;;
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


