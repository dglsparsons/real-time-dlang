#!/usr/bin/rdmd

import RealTime, 
       std.stdio; 


class myInterruptable : Interruptable 
{
    this()
    {
        super(&run); 
    }
    private void run()
    {
        writeln("Hello"); 
    }
}

void main()
{
    void thread_fn()
    {
        new myInterruptable().start(); 
    }

    enableInterruptableSections; 
    new RTThread(&thread_fn).start(); 
}
