#!/usr/bin/rdmd 

import interruptible, core.thread, core.time, std.stdio;

void abortableFunction()
{
    while(true) 
    {
        Thread.sleep(100.msecs); 
        writeln("Hello"); 
    }
}

void main()
{
    enableInterruptibleSections;
    Interruptible intr = new Interruptible(&abortableFunction); 
    new Thread({
        Thread.sleep(1.seconds); 
        intr.interrupt; 
        writeln("intrD"); 
    }).start; 
    intr.start;

}
