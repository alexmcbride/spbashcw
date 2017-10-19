#! /bin/bash

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

get_dir_size()
{
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

count_files()
{
	# Gets number of files in specified directory
	echo $(($(ls -l $1 | wc -l) -1))
}

count_junk_files()
{
	# Gets number of files in junk directory
	echo $(count_files $JUNK_DIR)
}

list()
{
	# List files in junk dir.
	count=$(count_junk_files)
	echo "Junk directory list: $count file(s)"
	if [ $count -gt 0 ]
	then
		echo "================================================"
		printf "|  %12s  |  %8s  |  %12s  |\n" "NAME" "BYTES" "TYPE"
		echo "================================================"
		for file in $JUNK_DIR/*
		do
			size=$(du $file -b | cut -f1)
			name=$(basename $file)
			_type=$(file $file | cut -d':' -f2)
			printf "|  %12s  |  %8s  |  %12s  |\n" "$name" "$size" "$_type"
		done
		echo "================================================"
	fi
}

recover()
{
	# TODO: multiple files?
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
	# Interactively delete files in junk directory
	# TODO: specify files in optargs?
	total_files=$(count_junk_files)
	echo "Delete junk directory files ($total_files):"
	if [ $total_files -gt 0 ]
	then
		files=($(ls $JUNK_DIR))
		count=0
		deleted_count=0	
		
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
	for user in $user_list
	do
		user_junkdir=/home/$user/$JUNK_DIR_NAME
		if [ -d $user_junkdir ] && [ -r $user_junkdir ]
		then
			size=$(get_dir_size $user_junkdir)
			total_size=$(($total_size+$size))
			echo "$user $size bytes"
		fi		
	done
	echo "Total size: $total_size bytes"
}

# Handle SIGINT signal.
trap "echo \"Exiting...\"; echo \"Total junk files: $(count_junk_files)\"; exit 0" SIGINT

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
