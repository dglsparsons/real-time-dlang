#include <stdio.h>
#include <pthread.h>


int main(void) 
{
    pthread_mutex_t myMutex; 
    pthread_mutexattr_t attr; 
    pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT); 

    if (pthread_mutex_init(&myMutex, &attr))
        printf("oops\r\n"); 
}
