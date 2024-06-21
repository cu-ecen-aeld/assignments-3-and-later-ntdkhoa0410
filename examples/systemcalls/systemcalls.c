#include "systemcalls.h"
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{
	// call a system() with a command input
	int return_value;
	return_value = system (cmd);
	if (return_value == -1){
		return false;
	}
	else {
		return true;
	}
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
	va_end(args);
/*
 * TODO:
 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/
	pid_t pid_fork, pid_wait;
	int status; // check if wait is done
	pid_fork = fork();
	// if fork() is not done correctly
    	if(pid_fork == -1)
    	{
	    	perror("ERROR fork");
		return false;
    	}
    	// if fork() successfully, do execv()
	else if (pid_fork == 0)
	{
	    int ret;
	    ret = execv(command[0],command);
	    // execv() fails
	    if (ret == -1)
	    {
	    	perror("ERROR execv");
	    	exit(-1);
	    } 
    	}
    	
    	pid_wait = wait(&status);
    	if(pid_wait == -1)
    	{
	    perror("ERROR wait");
	    return false;
    	} 
    	else if (WIFEXITED(status)) 
    	{
        	if (WEXITSTATUS(status) != 0) 
        	{
            		perror("wait");
            		return false;
            	}
    	        else 
        	{
            		return true;
        	}          	
        }  
    return false;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char *command[count + 1];
    int i;
    for (i = 0; i < count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];
    va_end(args);
    // open the file to write, if fails, return false
    int fd = open(outputfile, O_WRONLY | O_TRUNC | O_CREAT, 0644);
    if (fd < 0)
    {
        perror("open");
        return false;
    }

    // fork process
    int kidpid;
    switch (kidpid = fork())
    {
    case -1:
        // false if fails to fork
        perror("fork");
        close(fd);
        return false;
    case 0:
        if (dup2(fd, 1) < 0)
        {
            perror("dup2");
            close(fd);
            exit(-1);
        }
        int ret = execv(command[0], command);
        if (ret == -1)
        {
            perror("execvp");
            close(fd);
            exit(-1);
        }
    }
    // Wait for child termination
    int status;
    if (waitpid(kidpid, &status, 0) == -1)
    {
        perror("waitpid");
        close(fd);
        return false;
    }
    close(fd);
    return WIFEXITED(status) && (WEXITSTATUS(status) == 0);
    /*
     * TODO
     *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
     *   redirect standard out to a file specified by outputfile.
     *   The rest of the behaviour is same as do_exec()
     *
     */
}
