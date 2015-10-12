#!/usr/bin/rdmd

import std.stdio;
import core.thread; 
import core.sys.posix.sched; 


void main()
{
    writeln("Program Started"); 
    sched_param sp = { sched_priority: 50 }; 
    int ret = sched_setscheduler(0, SCHED_FIFO, &sp); 
    if (ret == -1) {
        throw new Exception("scheduler did not properly set");
    }
    writeln("Starting threads"); 

    new AThread().start(); 
    new BThread().start(); 

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
        Thread.sleep(2.seconds); 
        writeln("High Prio thread has woken - preemption is working"); 
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
        this.priority(51); 
        while(1) {
        }
    }
}
