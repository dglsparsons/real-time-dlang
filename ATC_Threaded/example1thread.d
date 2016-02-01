#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible_with_thread,
       RealTime : setScheduler, SCHED_FIFO; 

__gshared Interruptible a;

void interruptibleFunction()
{
    while(true) {
        Thread.sleep(1.seconds);
        writeln("Inside an interruptible section");
    }
}

void interruptThread()
{
    Thread.sleep(5.seconds); 
    a.interrupt();
}

void main()
{
    new Thread(&interruptThread).start();
    Interruptible a = Interruptible(&interruptibleFunction);
    a.start();
    writeln("End of process");
}

/** 
  * This basic example tests whether a basic interrupt is correctly handled,
  * causing the interruptible section to get exited
  **/
