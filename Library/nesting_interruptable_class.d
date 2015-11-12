#!/usr/bin/rdmd

import RealTime, 
       std.stdio, 
       core.thread, 
       core.memory; 



void thread_function()
{
    void delegate() pointer; 

    void nested_interruptable_section(InterruptableSection self)
    {
        int i = 5; 
        void fn()
        {
            writeln("test: ", i); 
        }
        pointer = &fn; 

        while(true)
        {
            Thread.sleep(1.seconds); 
            writeln("This is a nested interruptable section"); 
        }
    }

    void interruptable_section(InterruptableSection self)
    {
        new InterruptableSection(&nested_interruptable_section).start(); 
        while(true) 
        {
            Thread.sleep(1.seconds); 
            writeln("Thread is here!"); 
        }
    }

    void something()
    {
        int x = 10; 
        int y = 10; 
        int z = 10; 
    }

    writeln("Thread started"); 
    auto a = new InterruptableSection(&interruptable_section);
    a.start; 
    writeln("now here: "); 
    something(); 
    pointer(); 
}


void main()
{
    enableInterruptableSections; 
    auto a = new RTThread(&thread_function); 
    a.start(); 
    Thread.sleep(3.seconds); 
    //a.interruptableSections[1].toThrow = true; 
    a.interruptableSections[0].toThrow = true; 
    a.interrupt; 
}
