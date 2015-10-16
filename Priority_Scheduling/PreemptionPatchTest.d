#!/usr/bin/rdmd

import std.stdio;
import core.thread; 
import core.sys.posix.sched; 

shared bool shouldExit = false; 

void main()
{
    sched_param sp = { sched_priority: 50 }; 
    int ret = sched_setscheduler(0, SCHED_FIFO, &sp); 
    if (ret == -1) {
        throw new Exception("scheduler did not properly set");
    }
    writeln("Starting threads"); 
    
    new AThread().start(); 
    Thread.sleep(1.seconds); 
    new BThread().start(); 

    thread_joinAll; 
    writeln("finished"); 
}

class AThread : Thread
{
    this()
    {
        super(&run);
    }
    private:
    void run()
    {
    	this.priority(90); 
        writeln("High Prio thread started!"); 
        Thread.sleep(5.seconds); 
        writeln("High Prio thread has woken - preemption is working"); 
        shouldExit = true; 
    }
}

class BThread : Thread 
{
    this()
    {
        super(&run); 
    }
    private: 
    void run()
    {
        this.priority(1); 
        writeln("Low Priority thread started!"); 
        while(!shouldExit) {
        }
    }
}
