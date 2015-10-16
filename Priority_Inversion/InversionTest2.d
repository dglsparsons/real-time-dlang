#!/usr/bin/rdmd

import std.stdio; 
import core.thread; 
import core.sys.posix.pthread; 
import MutexWithPriorityInheritance; 

__gshared MutexWithPriorityInheritance myMutex; 
__gshared should_continue = false; 

class LowPriorityThread : Thread
{
    this()
    {
        super(&run);
    }
    private: 
    void run(){
        this.priority(10);
        writeln("starting low Priority thread with priority: ", this.priority); 
        myMutex.lock; 
        writeln("low priority thread has locked the mutex"); 
        while(!should_continue){} 
        writeln("Continuing low priority thread"); 
        myMutex.unlock; 
    }
}

class MediumPriorityThread : Thread
{
    this()
    {
        super(&run);
    }
    private: 
    void run(){
        this.priority(20);          
        writeln("Starting Medium Priority thread with priority: ", this.priority); 
        while(!should_continue) {}
        writeln("Ending Medium Priority thread"); 
    }
}

class HighPriorityThread : Thread
{
    this()
    {
        super(&run);
    }
    private: 
    void run(){
        this.priority(30); 
        writeln("Starting High Priority thread with priority: ", this.priority); 
        should_continue = true; 
        myMutex.lock; 
        writeln("High priority thread has locked the mutex"); 
        myMutex.unlock; 
    }
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
    new LowPriorityThread().start; 
    Thread.sleep(1.seconds); 
    new MediumPriorityThread().start; 
    Thread.sleep(1.seconds); 
    new HighPriorityThread().start; 
    thread_joinAll; 
}
