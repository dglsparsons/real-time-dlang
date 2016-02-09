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
        Thread.sleep(200.msecs);
        void output()
        {
            writeln("Third interruptible section");
        }
        getInt.executeSafely(&output);
    }
}

void mySecondInterruptibleFunction()
{
    auto fn = delegate{ 
        c = new Interruptible(&myThirdInterruptibleFunction);
    };
    getInt.executeSafely({ 
            c = new Interruptible(&myThirdInterruptibleFunction);
            }
            );
    c.start();
    while(true)
    {
        Thread.sleep(200.msecs); 
        auto output = delegate {
            writeln("Nested Interrupt!"); 
        };
        getInt.executeSafely(output);
    }
}

void interruptibleFunction()
{
    void fn()
    {
        b = new Interruptible(&mySecondInterruptibleFunction); 
    }
    getInt.executeSafely(&fn);
    b.start(); 

    while(true)
    {
        void output()
        {
            writeln("Outer interruptible");
        }
        Thread.sleep(200.msecs); 
        getInt.executeSafely(&output);
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

    Thread.sleep(1.seconds); 
    b.interrupt();

    Thread.sleep(1.seconds); 
    a.interrupt();
    //Thread.sleep(5.seconds);
    //Thread.sleep(5.seconds);
    //a.interrupt();

    mythread.join;
}
