#!/bin/sh
# Check if the number of arguements are correct
if [ $# -ne 2 ]
then
	echo "Please enter the write format"
	echo "Format: finder.sh FILESDIR SEARCHSTR"
	echo "Example: finder.sh /tmp/aesd/assignment1 linux"
	exit 1
# If the arguements are provided correctly
else
	filesdir=$1
	searchstr=$2
	# Check for directory valid or not
	if [ ! -d "$filesdir" ]
	then 
		echo "Not a valid directory, please retry"
		exit 1
	# If the inputs are correct, check for number of files in the directory and search for total matching lines
	else
		num_files=$(find "$filesdir" -type f | wc -l)
		num_matching_lines=$(grep -r "$searchstr" "$filesdir" | wc -l)
		echo "The number of files are "$num_files" and the number of matching lines are "$num_matching_lines""
	fi	
	exit 0
fi
