#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible;

__gshared Interruptible a;

void interruptThis()
{
    Thread.sleep(1.seconds);
    a.interrupt();
    writeln("Interrupted");
}

void interruptibleFunction() 
{
    writeln("Entered interruptible");

    self.deferred = true; 

    for(int i = 0; i < 2_000_000; i++)
    {
        // keep the processor busy for as long as possible..
        //self.deferred = true;
        writeln("i ", i);
        //self.deferred = false;
        //self.testCancel;
    }

    writeln("Thread wasn't cancelled!");
}

void main()
{
    enableInterruptibleSections();
    new Thread(&interruptThis).start();
    a = new Interruptible(&interruptibleFunction); 
    a.start();
}
