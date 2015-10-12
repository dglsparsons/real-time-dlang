#!/usr/bin/rdmd

import std.stdio;
import core.thread; 
import core.sys.posix.sched; 

void main()
{
    sched_param sp = { sched_priority: 50 }; 
    int ret = sched_setscheduler(0, SCHED_FIFO, &sp); 
    if (ret == -1) {
        throw new Exception("scheduler did not properly set");
    }
    
    auto a = new AThread().start(); 
    auto b = new BThread().start(); 

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
        this.priority(1); 
        while(1) {
        }
    }
}
