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
    void interruptable_section(InterruptableSection self)
    {
        //disable the interrupts
        auto level = RTThread.getSelf.depth -1;
        self.interruptable = false;

        //sleep for a while while we get an interrupt
        writeln("Disabling"); 
        Thread.sleep(3.seconds); 

        //enable interrupts and hopefully, immediately exit
        writeln("Enabling"); 
        self.interruptable = true; 
        while(true){} 
    }

    auto a = new InterruptableSection(&interruptable_section); 
    a.start(); 
}
