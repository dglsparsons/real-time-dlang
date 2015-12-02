#!/usr/bin/rdmd

import core.thread, 
       std.stdio; 

__gshared Fiber a; 

void fiberFunc()
{
    while(true)
    {
        Thread.sleep(1.seconds); 
        writeln("Hello, World!"); 
    }
}

void threadFunc()
{
    Thread.sleep(3.seconds); 
    writeln("Attempting to interrupt"); 
    Fiber.yieldAndThrow(new Exception("HELLO")); 
}

void main()
{
    a = new Fiber(&fiberFunc); 
    try {
        a.call(); 
    } catch (Exception ex) {
        writeln("caught"); 
    }
}
