#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible_with_thread, 
       core.sys.posix.pthread,
       RealTime : setScheduler, SCHED_FIFO; 

__gshared Interruptible a;
__gshared Interruptible b;
__gshared Interruptible c;


extern (C) void thread_cleanup(void* arg) nothrow
{
    int num = cast(int)arg; 
    printf("cleanup: %i\n", num); 
}

void testfn()
{
    auto a = addCleanup(&thread_cleanup, cast(void*)10);
    scope(exit) a.remove;
    auto b = addCleanup(&thread_cleanup, cast(void*)11);
    scope(exit) b.remove;
    auto c = addCleanup(&thread_cleanup, cast(void*)12);
    scope(exit) c.remove;
}

void myThirdInterruptibleFunction()
{
    testfn();
    addCleanup(&thread_cleanup, cast(void*)3);
    //scope(exit) removeCleanup(0); 
    addCleanup(&thread_cleanup, cast(void*)4);
    //scope(exit) removeCleanup(1);

    while(true)
    {
        Thread.sleep(1.seconds);
        writeln("Third interruptible section");
    }
}

void mySecondInterruptibleFunction()
{
    //pthread_cleanup cleanup = void; 
    //cleanup.push(&thread_cleanup, cast(void*)2);
    addCleanup(&thread_cleanup, cast(void*)2);
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
    //pthread_cleanup cleanup = void; 
    //cleanup.push(&thread_cleanup, cast(void*)1);
    addCleanup(&thread_cleanup, cast(void*)1);
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
    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();

    Thread.sleep(5.seconds); 
    a.interrupt();

    Thread.sleep(1.seconds); 
    //a.interrupt();
    //Thread.sleep(5.seconds);
    //Thread.sleep(5.seconds);
    //a.interrupt();

    mythread.join;
}

/** 
  * Testing that adding cleanup, and removing cleanup works properly.
  **/
