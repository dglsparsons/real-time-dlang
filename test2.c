#include <stdio.h> 
#include <pthread.h> 

void main()
{
    struct sched_param sp = { .sched_priority = 50 }; 
    int ret = sched_setscheduler(0, SCHED_FIFO, &sp); 
    if (ret == -1)
        printf("Scheduler did not properly set"); 
}
