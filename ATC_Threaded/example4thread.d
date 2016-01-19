#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible_with_thread, 
       core.sys.posix.pthread;

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

    self.deferred = false; 

    for(int i = 0; i < 2_000_000; i++)
    {
        // keep the processor busy for as long as possible..
        self.deferred = true; 
        writeln("i ", i);
        self.deferred = false;
    }

    writeln("Thread wasn't cancelled!");
}

void main()
{
    new Thread(&interruptThis).start();
    a = new Interruptible(&interruptibleFunction); 
    a.start();
}
