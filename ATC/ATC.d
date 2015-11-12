#!/usr/bin/rdmd

import RealTime, 
       core.thread,
       std.stdio, 
       std.conv; 

void threadFunc()
{
    RTThread self = to!RTThread(Thread.getThis()); 
    self.interruptable = true; 
    // interruptable section of code
    try 
    {
        while(true)
        {
            Thread.sleep(1.seconds); 
            writeln("Hello, I am a thread"); 
        }
    } 
    catch (AsyncException e)

    self.interruptable = false; 

    while(true)
    {
        writeln("Thread is now down here"); 
        Thread.sleep(1.seconds); 
    }
}

void main()
{
    enableInterruptableSections(); 

    auto a = new RTThread(&threadFunc); 
    a.start(); 

    Thread.sleep(3.seconds); 
    a.interrupt; 

    while(true)
    {
        Thread.sleep(2.seconds); 
        a.interrupt; 
    }
}

