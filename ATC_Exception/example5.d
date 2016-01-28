#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible, 
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

    getInt.deferred = true; 

    for(int i = 0; i < 2_000_000; i++)
    {
        void print_i() 
        {
            printf("i %i\n", i);
        }
        // keep the processor busy for as long as possible..
        //getInt.deferred = true; 
        //a.deferred = true;
        getInt.executeSafely(&print_i);
        //a.deferred = false;
        //getInt.deferred = false;
        //getInt.testCancel;
    }

    writeln("Thread wasn't cancelled!");
}

void outerInterruptible() 
{
    //getInt.deferred = true;
    Interruptible b;
    void initInterruptible() 
    {
        b = new Interruptible(&interruptibleFunction);
    }
    getInt.executeSafely(&initInterruptible);
    b.start();
}

void main()
{
    enableInterruptibleSections;
    new Thread(&interruptThis).start();
    a = new Interruptible(&outerInterruptible);
    a.start();
}


/** 
  * Using this test, the inner function should be cancelled, even though 
  * it is set to defer interrupts. This is beacuse the outmost one is
  * cancelled. 
  **/
