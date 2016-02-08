#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible;

__gshared Interruptible a;

void threadFunction()
{
    while(true) {
        Thread.sleep(200.msecs);
        writeln("Hello, World!");
        writeln("Thread: ", Thread.getThis);
    }
}

void thread_to_spawn_interruptible()
{
    a = new Interruptible(&threadFunction);  
    a.start(); 
    writeln("Thread ending"); 
}

void main()
{
    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();
    Thread.sleep(1.seconds);
    a.interrupt();
    mythread.join;
}

/** 
  * This basic example should test that a basic interrupt can be handled,
  * causing the interruptible section to get cancelled 
  **/
