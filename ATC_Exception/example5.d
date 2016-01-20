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

    self.deferred = true; 

    for(int i = 0; i < 2_000_000; i++)
    {
        // keep the processor busy for as long as possible..
        printf("i %i\n", i);
        //self.testCancel;
    }

    writeln("Thread wasn't cancelled!");
}

void outerInterruptible()
{
    auto b = new Interruptible(&interruptibleFunction);
    b.start();
}

void main()
{
    new Thread(&interruptThis).start();
    a = new Interruptible(&outerInterruptible);
    a.start();
}


/** 
  * Using this test, the inner function should be cancelled, even though 
  * it is set to defer interrupts. This is beacuse the outmost one is
  * cancelled. 
  **/
