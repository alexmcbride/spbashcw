#! /bin/bash

# Constants
SIGINT=2
MAX_SIZE=1024 # KBs
USAGE="usage: $0 <fill in correct usage>" 
JUNK_DIR=~/.junkdir

# Variables
total_files=0

# Functions
command_list()
{
	ls $JUNK_DIR
}

recover()
{

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
     l) echo "l option"; command_list;;
     r) echo "r option; data: $OPTARG";;
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
         "list") echo "l"; command_list;;
         "recover") echo "r";;
         "delete") echo "d";;
         "total") echo "t";;
         "watch") echo "w";;
         "kill") echo "k";;
         "exit") exit 0;;
         *) echo "unknown option";;
         esac
      done
 fi
else echo "extra args??: $@"
fi


