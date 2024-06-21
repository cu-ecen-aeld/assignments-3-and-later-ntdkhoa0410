#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <syslog.h>

int main (int argc, char * argv[]){
	//Open log to write log messages
	openlog("writer", LOG_PID, LOG_USER);
	
	//Check if argurements are enough or not
	if (argc != 3){
		syslog(LOG_ERR, "Invalid number of arguments: %d", argc);
		closelog();
		return 1;
    	}
    	//If arguements are given correctly
	const char *writefile = argv[1];
    	const char *writestr = argv[2];
    	
    	//Open the file to WRITE
	int fd = open(writefile, O_WRONLY | O_CREAT | O_TRUNC, S_IRWXU);
    	if (fd == -1){
    		syslog(LOG_ERR, "Error opening file : %s", writefile);
    		closelog();
    		return 1;
    	}
    	//WRITING file
    	ssize_t nr = write (fd, writestr, strlen (writestr));
    	if (nr == -1){
    		/* error */	
    		syslog(LOG_ERR, "Error writing file : %s", writefile);
    		closelog();
    		return 1;
    	}
    	    	
    	//After completing task
    	syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);

    	//Close file
    	int close_file = close (fd);
    	
    	//Close log
    	closelog();
    	return 0;
}
