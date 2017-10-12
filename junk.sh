#! /bin/bash

# Constants
SIGINT=2
MAX_DIR_LIMIT=1024 # Bytes
USAGE="usage: $0 <fill in correct usage>" 
JUNK_DIR=~/.junkdir

# Variables
total_files=0

# Functions
check_junk_dir_limit()
{
	# Warn if junk directory size goes over limit
	bytes=$(du -sb $JUNK_DIR | cut -f1)
	if [ $bytes -gt $MAX_DIR_LIMIT ]
	then
		echo "Warning: junk directory size greater than $MAX_DIR_LIMIT bytes ($bytes bytes)" 1>&2
	fi
}

junk_file()
{
	# TODO: readable files?
	# Move file to junk directory
	if [ -d $1 ]
	then
		echo "Error: can't junk directory" 1>&2
	elif [ -f $1 ]
	then
		dest_path="$JUNK_DIR/$1"
		mv $1 $dest_path
		echo "File '$1' junked!"
		check_junk_dir_limit
	else
		echo "Error: '$1' does not exist" 1>&2
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
		echo "File '$1' restored"
	else
		echo "Error: '$1' does not exist" 1>&2
	fi
}

recover_prompt()
{
	# Ask user which file to recover
	echo -n "Enter file to restore: "
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

create_junk_dir()
{
	# Create junk directory if does not exist
	if [ ! -d $JUNK_DIR ]
	then
		mkdir $JUNK_DIR
		echo "Created junk directory '$JUNK_DIR'"
	fi
}

# Handle SIGINT signal.
trap "echo \"Total junk files: $total_files\"; exit 0" SIGINT

# Print student name and ID
echo "Alex McBride (S1715224)"

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
then if (( $OPTIND == 1 )) 
 then select menu_list in list recover delete total watch kill exit
      do case $menu_list in
         "list") list;;
         "recover") recover_prompt;;
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
	junk_file $1
fi


