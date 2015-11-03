#!/usr/bin/rdmd

import RealTime, 
       std.stdio, 
       core.thread;

void thread_function()
{
    void nested_interruptable_section()
    {
        while(true)
        {
            Thread.sleep(1.seconds); 
            writeln("This is a nested interruptable section"); 
        }
    }

    void interruptable_section()
    {
        new Interruptable(&nested_interruptable_section).start(); 
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
    //a.interruptableSections[1].toThrow = true; 
    a.interruptableSections[0].toThrow = true; 
    a.interrupt; 
}
