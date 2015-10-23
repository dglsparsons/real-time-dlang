#!/usr/bin/rdmd

import core.thread;
import core.sys.posix.sched; 
import core.sys.posix.pthread; 
import std.stdio;

class AThread : Thread
{
    this()
    {
        super(&run);
    }

    private:
    void run()
    {
        //This method of changing the priority works, but only from inside the
        //thread itself
    	this.priority(90); 
        writeln("priority of A thread: ", this.priority); 
        foreach (number; 1..1000) {
            writeln("A: ", number, " ", this.priority);
        }
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
        writeln("priority of B thread: ", this.priority); 
        foreach (number; 1..1000) {
            writeln("B: ", number, " ", this.priority);
        }
    }
}

void main()
{
    sched_param sp = { sched_priority: 50 }; 
    int ret = sched_setscheduler(0, SCHED_FIFO, &sp); 
    if (ret == -1) {
        throw new Exception("scheduler did not properly set");
    }

    //Check what the max and min priorities are
    int max_prio = sched_get_priority_max(sched_getscheduler(0)); 
    int min_prio = sched_get_priority_min(sched_getscheduler(0)); 
    writeln("schedulers max_prio: ", max_prio, " min prio: ", min_prio); 

    //Create a new thread and check its MAX and MIN priorities
    auto a = new AThread();
    a.start();
    auto b = new BThread().start(); 
    auto c = new AThread().start; 
    auto d = new AThread().start; 
    auto e = new AThread().start; 
}