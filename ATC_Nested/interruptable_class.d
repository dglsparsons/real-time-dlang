#!/usr/bin/rdmd

import RealTime, 
       std.stdio, 
       core.thread, 
       std.conv; 
/*
class AsyncInterrupt : Error
{
    public int depth; 
    this(int d)
    {
        super(null, null); 
        this.depth = d; 
    }
}*/

class Interruptable
{
    uint depth; 
    void delegate() exec; 

    this(void function() fn)
    {
        //this.exec = fn; 
    }
    this(void delegate() fn)
    {
        this.exec = fn; 
    }

    private: 
    void start()
    {
        RTThread self = to!RTThread(Thread.getThis); 
        self.depth++; 
        try {
            self.interruptable = true; 
            exec(); 
        } 
        catch (AsyncInterrupt caughtex)
        {
            if (true)//depth == caughtex.depth)
                writeln("exception caught"); 
            else 
            {
                writeln("Exception being rethrown");
                throw caughtex; 
            }
        }
        finally 
        {
            self.interruptable = false; 
            self.depth--; 
        }
    }
}

void thread_function()
{
    RTThread self = to!RTThread(RTThread.getThis); 

    void interruptable_section()
    {
        while(true) 
        {
            Thread.sleep(1.seconds); 
            writeln("Thread is here!"); 
        }
    }

    writeln("Thread started"); 
    auto a = new Interruptable(&interruptable_section);//.start(); 
    a.start; 
}


void main()
{
    enableInterruptableSections; 
    auto a = new RTThread(&thread_function); 
    a.start(); 
    Thread.sleep(1.seconds); 
    a.interrupt(); 
}
