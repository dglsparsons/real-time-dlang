#!/usr/bin/rdmd

void main()
{
    import std.stdio; 
    import core.thread;
    import core.sys.posix.pthread; 
    // Create a mutex
    pthread_mutex_t myMutex;
    pthread_mutexattr_t attr; 
    // Set the protocol
    //pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT); 
    // only possible on OSX and solaris? 
    // https://github.com/D-Programming-Language/druntime/blob/master/src/core/sys/posix/pthread.d
    // This works fine in C - requires a change to the runtime? 
    if ( pthread_mutex_init( &myMutex, &attr ))
        throw new Error("Unable to initilise mutex"); 

}
