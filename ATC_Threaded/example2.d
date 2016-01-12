#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible, 
       RealTime : setScheduler, SCHED_FIFO; 

__gshared Interruptible a;

void mySecondInterruptibleFunction()
{
    while(true)
    {
        Thread.sleep(1.seconds); 
        writeln("Nested Interrupt!");
    }
}

void interruptibleFunction()
{
    auto x = new Interruptible(&mySecondInterruptibleFunction); 
    x.start(); 

    for (int i = 0; i < 3; i++)
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
    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();

    Thread.sleep(10.seconds); 
    a.interrupt();

    mythread.join;
}
