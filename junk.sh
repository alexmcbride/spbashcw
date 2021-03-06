#! /bin/bash

echo "Student: Alex McBride (S1715224)"

USAGE="usage: $0 [file...] | [-l | -r file | -d | -t | -w | -k]" 
JUNK_DIR_LIMIT=1
JUNK_DIR_NAME=.junkdir
JUNK_DIR=~/$JUNK_DIR_NAME

create_junk_dir()
{
	if [[ ! -d $JUNK_DIR ]]
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
	if [[ -d $1 ]]
	then
		echo "Error: '$1' is a directory" 1>&2
	elif [[ ! -f $1 ]]
	then
		echo "Error: source file '$1' does not exist" 1>&2
	elif [[ -f $2 ]]
	then
		echo "Error: destination file '$2' already exists" 1>&2
	elif [[ ! -r $1 ]]
	then
		echo "Error: source file '$1' is not readable" 1>&2
	elif [[ ! -w $(dirname $2) ]]
	then
		echo "Error: destination directory '$(dirname $2)' not writable" 1>&2
	else
		return $(mv "$1" "$2")
	fi
	return 1
}

get_dir_size()
{
	echo $(du -sk $1 | cut -f1)
}

check_junk_dir_size()
{
	bytes=$(get_dir_size $JUNK_DIR)
	if [[ $bytes -gt $JUNK_DIR_LIMIT ]]
	then
		echo "Warning: junk directory size greater than ${JUNK_DIR_LIMIT}KB (${bytes}KB)" 1>&2
	fi
}

junk_files()
{
	moved_count=0

	for file in $@
	do
		dest_path=$JUNK_DIR/$file
		if move_file $file $dest_path
		then
			moved_count=$((moved_count+1))
		fi		
	done

	if [[ $moved_count -gt 0 ]]
	then
		echo "Junk: $moved_count file(s) moved to junk directory!"
		check_junk_dir_size	
	fi
}

count_files()
{
	if [[ -d $1 ]]
	then
		echo $(($(ls -l $1 | wc -l) -1))
	else
		echo "0"
	fi
}

count_junk_files()
{
	echo $(count_files $JUNK_DIR)
}

list()
{
	count=$(count_junk_files)
	echo "Junk directory list: $count file(s)"
	if [[ $count -gt 0 ]]
	then
		echo "Name          KB             Type"
		echo "----------    -----------    ----------"
		for file in $JUNK_DIR/*
		do
			size=$(du $file -ks | cut -f1)
			name=$(basename $file)
			filetype=$(file $file | cut -d':' -f2)
			printf "%-12s  %-12s  %-12s\n" "$name" "$size" "$filetype"
		done
	fi
}

recover()
{
	source_path="$JUNK_DIR/$1"
	dest_path=./$1
	if move_file $source_path $dest_path
	then
		echo "File '$1' recovered"
	fi
}

recover_with_prompt()
{
	total_files=$(count_junk_files)
	if [[ $total_files -gt 0 ]]
	then
		echo -n "Enter file to recover: "
		read filename
		recover $filename
	else
		echo "Recover junk directory: $total_files file(s)" 1>&2
	fi
}

delete()
{
	total_files=$(count_junk_files)
	echo "Delete junk directory: $total_files file(s)"
	if [[ ! -w $JUNK_DIR  ]]
	then
		echo "Error: junk dir '$JUNK_DIR' is not writable" 1>&2
	elif [[ $total_files -gt 0 ]]
	then
		files=($(ls $JUNK_DIR))
		count=0
		deleted_count=0	

		while [[ $count -lt $total_files ]]
		do
			filename=${files[$count]}
			echo -n "Delete file '$filename'? (y/n): "
			read choice
			case $choice in
				[yY] | [yY][Ee][Ss] )
					rm -f $JUNK_DIR/$filename
					count=$(($count+1))
					deleted_count=$(($deleted_count+1))
				;;
				[nN] | [n|N][O|o] )
					count=$(($count+1))
				;;
				*) echo "Invalid input" 1>&2
			esac
		done

		if [[ $deleted_count -gt 0 ]]
		then
			echo "Deleted $deleted_count file(s)"
		fi
	fi
}

total()
{
	user_list=$(cut -d: -f1 /etc/passwd)
	total_size=0
	user_count=0

	for user in $user_list
	do
		user_junkdir=/home/$user/$JUNK_DIR_NAME
		if [[ -d $user_junkdir ]] && [[ -r $user_junkdir ]]
		then
			size=$(get_dir_size $user_junkdir)
			total_size=$(($total_size+$size))
			user_count=$(($user_count+1))
		fi		
	done

	echo "Total junk directory size for $user_count user(s): ${total_size}KB"
}

start_watch()
{
	./watch.sh $JUNK_DIR
}

stop_watch()
{
	./watch.sh -k
}

handle_trap()
{
	echo
	echo "Total junk files: $(count_junk_files)"
	echo "Exiting..."
	exit 1
}

trap handle_trap SIGINT

create_junk_dir

while getopts :lr:dtwk args
do
	case $args in
		l) list;;
		r) recover $OPTARG;;
		d) delete;; 
		t) total;; 
		w) start_watch;; 
		k) stop_watch;;     
		:) echo "data missing, option -$OPTARG";;
		\?) echo "$USAGE";;
	esac
done

((pos = OPTIND - 1))
shift $pos

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
				"kill") stop_watch;;
				"exit") exit 0;;
				*) echo "unknown option";;
			esac
		done
	fi
else
	junk_files $@
fi
