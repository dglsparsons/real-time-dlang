#!/usr/bin/rdmd

import RealTime, 
       std.stdio,
       core.thread;  


void main()
{
    enableInterruptableSections; 
    auto a = new RTThread(&thread_function);
    a.start;
    Thread.sleep(2.seconds);
    a.interruptableSections[0].toThrow = true; 
    a.interrupt; 
}


void thread_function()
{
    void interruptable_section()
    {
        //disable the interrupts
        //auto self = RTThread.getSelf; 
        RTThread.getSelf.interruptableSections[0].interruptable = false;

        //sleep for a while while we get an interrupt
        writeln("Disabling"); 
        Thread.sleep(3.seconds); 

        //enable interrupts and hopefully, immediately exit
        writeln("Enabling"); 
        RTThread.getSelf.interruptableSections[0].interruptable = true; 
    }

    auto a = new Interruptable(&interruptable_section); 
    a.start(); 
}
