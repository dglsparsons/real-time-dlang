#!/usr/bin/rdmd

import RealTime; 
import std.stdio; 
import core.thread; 

void main()
{
    void test()
    {
        writeln("new thread!"); 
    }
    new RTThread(&test).start(); 
}
