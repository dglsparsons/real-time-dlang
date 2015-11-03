#!/usr/bin/rdmd

import std.stdio;
import etc.linux.memoryerror; 
import core.thread;
import RealTime; 
import std.conv; 

class MyThread : RTThread
{
    MonoTime time; 
    int id; 
    this(MonoTime time, int i)
    {
        this.time = time;
        this.id = i; 
        super(&run); 
    }
    private: 
    void run()
    {
        RTThread self = to!RTThread(Thread.getThis());
        self.interruptable = true; 
        try {
            scope(exit) self.interruptable = false; 
            delay_until(time); 
            self.interrupt; 
        } catch (AsyncException) {
            writeln(id, "SUCCESS!"); 
        }
    }
}

void main()
{
    import core.time; 
    auto time = MonoTime.currTime; 
    time += 4.seconds;
    enableInterruptableSections;
    for (int i = 0; i < 20; i++)
    {
        new MyThread(time, i).start(); 
    }
}
