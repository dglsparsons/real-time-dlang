#include <stdio.h> 
#include <pthread.h> 
#include <sched.h> 

pthread_mutex_t myMutex; 

void *PrintHello(void *threadid)
{

    long tid;
    tid = (long)threadid;
    int policy; 
    struct sched_param param; 
    pthread_t self = pthread_self(); 
    pthread_setschedprio(self, tid); 
    if (pthread_getschedparam(self, &policy, &param)) {
        printf("THREAD UNABLE TO GET PRIORITY"); 
    }
    printf("Hello World! It's me, thread #%ld! At priority %i.\n", tid, param.sched_priority);
    pthread_exit(NULL);
}

void main()
{
    // Set a real time scheduler 
    struct sched_param sp = { .sched_priority = 50 }; 
    int ret = sched_setscheduler(0, SCHED_FIFO, &sp); 
    if (ret == -1) {
        printf("Scheduler not properly set\r\n"); 
    }

    // Create a mutex
    pthread_mutexattr_t mutexattr_prioinherit;  
    int mutex_protocol;
    pthread_mutexattr_init(&mutexattr_prioinherit); 
    pthread_mutexattr_getprotocol(&mutexattr_prioinherit, &mutex_protocol); 
    if (mutex_protocol != PTHREAD_PRIO_INHERIT) {;  
        pthread_mutexattr_setprotocol(&mutexattr_prioinherit, PTHREAD_PRIO_INHERIT);    
    }

    // Start some threads 
    pthread_t threads[5];
    int rc;
    long t; 
    for(t=0; t<5; t++){
        rc = pthread_create(&threads[t], NULL, PrintHello, (void *)t);
        if (rc){
            printf("ERROR; return code from pthread_create() is %d\n", rc);
        }
    }

    pthread_exit(NULL);


}
