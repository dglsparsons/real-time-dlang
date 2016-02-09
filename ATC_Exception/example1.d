#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible;

__gshared Interruptible a;

void interruptibleFunction()
{
    while(true)
    {
        Thread.sleep(200.msecs);
        writeln("Inside an interruptible section");
    }
}

void interruptThread() 
{
    Thread.sleep(1.seconds); 
    a.interrupt();
}

void main()
{
    enableInterruptibleSections;
    new Thread(&interruptThread).start();
    a = new Interruptible(&interruptibleFunction);
    a.start();
    writeln("End of process");
}
