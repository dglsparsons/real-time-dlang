#include <stdio.h> 
#include <stdlib.h>
#include <signal.h>
#include <sys/wait.h>
#include <string.h>
#include <unistd.h>

void main()
{
    int status; 
    int a, b, c; 

    if (fork())
    {
        /* Parent */
        wait (&status); 
        if (WIFEXITED(status))
            printf("Child exited normally with exit status %d\n", WEXITSTATUS(status));
        if (WIFSIGNALED(status))
            printf("Child exited on signal %d: %s\n", WTERMSIG(status), strsignal(WTERMSIG(status)));
    }
    else 
    {
        /* Child */
        printf("Child PID = %d\n", getpid()); 
        //*(int *)0 = 99; 
        sleep(3); 
        exit(5); 
    }
}
