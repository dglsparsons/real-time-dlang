#!/usr/bin/rdmd

import RealTime, 
       std.stdio; 


class myInterruptable : InterruptableSection
{
    this()
    {
        super(&run); 
    }
    private void run(InterruptableSection self)
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
