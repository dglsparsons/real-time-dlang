#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       interruptible; 



void threadFunction()
{
    while(true) {
        auto sleepDuration = 1.seconds + 500.msecs;
        Thread.sleep(sleepDuration);
        writeln("Hello, World!");
    }
}

void main()
{
   auto a = new Interruptible(&threadFunction);  
   a.start(); 
   Thread.sleep(5.seconds); 
   a.interrupt();
}
