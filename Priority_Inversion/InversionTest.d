#!/usr/bin/rdmd

import std.stdio; 
import core.thread; 
import core.sys.posix.pthread; 
import core.sys.posix.sched; 

__gshared pthread_mutex_t myMutex; 
__gshared should_continue = false; 

void lowPriorityThread()
{
    int newPriority = 10; 
    int policy; 
    sched_param param; 
    pthread_t self = pthread_self(); 
    if (pthread_setschedprio(self, newPriority))
        throw new Error("Unable to set thread priority"); 
    if (pthread_getschedparam(self, &policy, &param))
        throw new Error("Unable to get thread priority"); 
    writeln("starting low Priority thread with priority: ", param.sched_priority); 
    if (pthread_mutex_lock(&myMutex))
        throw new Error("Unable to LOCK mutex"); 
    writeln("low priority thread has locked the mutex"); 
    while(!should_continue){} 
    if (pthread_getschedparam(self, &policy, &param))
        throw new Error("Unable to get thread priority"); 
    writeln("continuing lowprio thread, priority: ", param.sched_priority); 
    if (pthread_mutex_unlock(&myMutex))
        throw new Error("Unable to UNLOCK mutex"); 
}

void mediumPriorityThread()
{
    int newPriority=20; 
    int policy; 
    sched_param param; 
    pthread_t self = pthread_self(); 
    if (pthread_setschedprio(self, newPriority))
        throw new Error("Unable to set thread priority"); 
    if (pthread_getschedparam(self, &policy, &param))
        throw new Error("Unable to get thread priority"); 
    writeln("Starting Medium Priority thread with priority: ", param.sched_priority); 
    while(!should_continue) {}
    writeln("Ending Medium Priority thread"); 
}

void highPriorityThread()
{
    int newPriority=30; 
    int policy; 
    sched_param param; 
    pthread_t self = pthread_self(); 
    if (pthread_setschedprio(self, newPriority))
        throw new Error("Unable to set thread priority"); 
    if (pthread_getschedparam(self, &policy, &param))
        throw new Error("Unable to get thread priority"); 
    writeln("Starting High Priority thread with priority: ", param.sched_priority); 
    should_continue = true; 
    if (pthread_mutex_lock(&myMutex))
        throw new Error("Unable to LOCK mutex"); 
    writeln("High priority thread has locked the mutex"); 
    if (pthread_mutex_unlock(&myMutex))
        throw new Error("Unable to unlock mutex"); 
    
}

void main()
{
    // Change the scheduler
    sched_param sp = { sched_priority: 50 }; 
    int ret = sched_setscheduler(0, SCHED_FIFO, &sp); 
    if (ret == -1) {
        throw new Exception("scheduler did not properly set");
    }
    writeln("Scheduler has been set"); 


    // Create a mutex
    pthread_mutexattr_t attr = void;

    if( pthread_mutexattr_init( &attr ) )
        throw new Error( "Unable to initialize mutex" );
    scope(exit) pthread_mutexattr_destroy( &attr );

    //if( pthread_mutexattr_settype( &attr, PTHREAD_MUTEX_RECURSIVE ) )
    //    throw new Error( "Unable to initialize mutex" );

    if (pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT))
        throw new Error("Unable to initialize prio inheritance"); 

    if( pthread_mutex_init( &myMutex, &attr ) )
        throw new Error( "Unable to initialize mutex" );
    writeln("Mutex has been initialised"); 


    // Create some Threads
     
    new Thread(&lowPriorityThread).start; 
    
    Thread.sleep(1.seconds); 
    new Thread(&mediumPriorityThread).start; 
    Thread.sleep(1.seconds); 
    new Thread(&highPriorityThread).start; 
    thread_joinAll; 
}
