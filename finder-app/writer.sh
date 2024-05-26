#!/bin/sh
# Check if the number of arguements are correct
if [ $# -ne 2 ]
then
	echo "Please enter the write format"
	echo "Format: writer.sh PATH_TO_FILE TEXT_TO_WRITE"
	echo "writer.sh /tmp/aesd/assignment1/sample.txt ios"
	exit 1
# If the arguements are provided correctly
else
	writefile=$1
	writestr=$2
	# Check if writefile argument is provided
	if [ -z "$writefile" ]; then
	    echo "Error: writefile argument not specified"
	    exit 1
	fi

	# Check if writestr argument is provided
	if [ -z "$writestr" ]; then
	    echo "Error: writestr argument not specified"
	    exit 1
	fi

	# Create directory path if it doesn't exist
	mkdir -p "$(dirname "$writefile")"

	# Write content to the file
	echo "$writestr" > "$writefile"

	# Check if file was successfully created
	if [ $? -ne 0 ]; then
	    echo "Error: Failed to create file $writefile"
	    exit 1
	fi

	echo "File $writefile successfully created with content: $writestr"
	exit 0
fi
