#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible;

__gshared Interruptible a;
__gshared Interruptible b;
__gshared Interruptible c;


void myThirdInterruptibleFunction()
{
    while(true)
    {
        Thread.sleep(1.seconds);
        writeln("Third interruptible section");
    }
}

void mySecondInterruptibleFunction()
{
    c = new Interruptible(&myThirdInterruptibleFunction);
    c.start();
    while(true)
    {
        Thread.sleep(1.seconds); 
        writeln("Nested Interrupt!");
    }
}

void interruptibleFunction()
{
    b = new Interruptible(&mySecondInterruptibleFunction); 
    b.start(); 

    while(true)
    {
        Thread.sleep(1.seconds); 
        writeln("Outer interruptible");
    }

}

void thread_to_spawn_interruptible()
{
    a = new Interruptible(&interruptibleFunction);  
    a.start(); 
    writeln("Thread ending"); 
}

void main()
{
    enableInterruptibleSections;
    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();

    Thread.sleep(5.seconds); 
    b.interrupt();

    Thread.sleep(5.seconds); 
    //a.interrupt();
    //Thread.sleep(5.seconds);
    //Thread.sleep(5.seconds);
    //a.interrupt();

    mythread.join;
}
