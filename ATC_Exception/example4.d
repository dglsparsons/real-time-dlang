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

    getInt.deferred = true; 

    for(int i = 0; i < 2_000_000; i++)
    {
        void output()
        {
            writeln("i ", i);
        }
        Interruptible.getThis.executeSafely(&output);
        getInt.testCancel;
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
