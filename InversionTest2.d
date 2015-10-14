#!/usr/bin/rdmd

import std.stdio; 
import core.thread; 
import core.sys.posix.pthread; 
import MutexWithPriorityInheritance; 

__gshared MutexWithPriorityInheritance myMutex; 
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
    myMutex.lock; 
    writeln("low priority thread has locked the mutex"); 
    while(!should_continue){} 
    if (pthread_getschedparam(self, &policy, &param))
        throw new Error("Unable to get thread priority"); 
    writeln("Continuing low priority thread, priority: ", param.sched_priority); 
    myMutex.unlock; 
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
    myMutex.lock; 
    writeln("High priority thread has locked the mutex"); 
    myMutex.unlock; 
}

void main()
{
    // Change the scheduler
    import RealTimeScheduling; 
    setScheduler(SCHED_FIFO, 50); 

    // Create a mutex
    myMutex = new MutexWithPriorityInheritance(); 
    writeln("Mutex has been initialised"); 

    // Create some Threads
    new Thread(&lowPriorityThread).start; 
    Thread.sleep(1.seconds); 
    new Thread(&mediumPriorityThread).start; 
    Thread.sleep(1.seconds); 
    new Thread(&highPriorityThread).start; 
    thread_joinAll; 
}
