#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible_with_thread,
       RealTime : setScheduler, SCHED_FIFO; 

__gshared Interruptible a;

void threadFunction()
{
    while(true) {
        auto sleepDuration = 1.seconds + 500.msecs;
        Thread.sleep(sleepDuration);
        writeln("Hello, World!");
    }
}

void thread_to_spawn_interruptible()
{
    Thread.getThis.priority = 75; // testing inheriting priority works
    a = new Interruptible(&threadFunction);  
    a.start(); 
    writeln("Thread ending"); 
}

void main()
{
    setScheduler(SCHED_FIFO, 50);
    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();
    Thread.sleep(5.seconds); 
    a.interrupt();
    mythread.join;
}
