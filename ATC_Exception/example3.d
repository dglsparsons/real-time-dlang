#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible;

__gshared Interruptible a;
__gshared Interruptible b;
__gshared Interruptible c;

void thread_cleanup(void* arg)
{
    int num = cast(int)arg; 
    printf("cleanup: %i\n", num); 
}


void testfn()
{
    auto a = getInt.addCleanup(&thread_cleanup, cast(void*)10);
    getInt.removeCleanup(a);
    auto b = getInt.addCleanup(&thread_cleanup, cast(void*)11);
    getInt.removeCleanup(b);
    auto c = getInt.addCleanup(&thread_cleanup, cast(void*)12);
    getInt.removeCleanup(c);
}

void myThirdInterruptibleFunction()
{
    testfn();
    getInt.addCleanup(&thread_cleanup, cast(void*)3);
    //scope(exit) removeCleanup(0); 
    getInt.addCleanup(&thread_cleanup, cast(void*)4);
    //scope(exit) removeCleanup(1);

    while(true)
    {
        Thread.sleep(200.msecs);
        void output() {
            writeln("Third interruptible section");
        }
        getInt.executeSafely(&output);
    }
}

void mySecondInterruptibleFunction()
{
    //pthread_cleanup cleanup = void; 
    //cleanup.push(&thread_cleanup, cast(void*)2);
    getInt.addCleanup(&thread_cleanup, cast(void*)2);
    c = new Interruptible(&myThirdInterruptibleFunction);
    c.start();
    while(true)
    {
        Thread.sleep(200.msecs); 
        writeln("Nested Interrupt!");
    }
}

void interruptibleFunction()
{
    //pthread_cleanup cleanup = void; 
    //cleanup.push(&thread_cleanup, cast(void*)1);
    getInt.addCleanup(&thread_cleanup, cast(void*)1);
    b = new Interruptible(&mySecondInterruptibleFunction); 
    b.start(); 

    while(true)
    {
        Thread.sleep(200.msecs); 
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

    Thread.sleep(1.seconds); 
    b.interrupt();

    //Thread.sleep(1.seconds); 
    //a.interrupt();
    Thread.sleep(1.seconds);
    //Thread.sleep(5.seconds);
    a.interrupt();

    mythread.join;
}
