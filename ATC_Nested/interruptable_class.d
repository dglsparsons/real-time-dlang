#!/usr/bin/rdmd

import RealTime, 
       std.stdio, 
       core.thread;

void thread_function()
{
    void interruptable_section(Interruptable self)
    {
        while(true) 
        {
            Thread.sleep(1.seconds); 
            writeln("Thread is here!"); 
        }
    }

    writeln("Thread started"); 
    auto a = new Interruptable(&interruptable_section);
    a.start; 
}


void main()
{
    enableInterruptableSections; 
    auto a = new RTThread(&thread_function); 
    a.start(); 
    Thread.sleep(3.seconds); 
    a.interruptableSections[0].toThrow = true; 
    a.interrupt; 
}
