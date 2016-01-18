#!/usr/bin/rdmd 

import std.stdio, 
       core.thread,
       interruptible; 


__gshared Interruptible a; 

void interruptibleFunction()
{
    while(true)
    {
        Thread.sleep(1.seconds);
        writeln("Inside an interruptible section of code"); 
    }
}

void interruptingFunction()
{
    Thread.sleep(5.seconds); 
    a.interrupt();
}

void main()
{
    enableInterruptableSections();
    new Thread(&interruptingFunction).start;
    a = new Interruptible(&interruptibleFunction);
    a.start(); 
    writeln("Back in the main function");
}
