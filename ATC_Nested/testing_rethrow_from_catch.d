#!/usr/bin/rdmd 

import std.stdio, 
       core.thread,
       RealTime; 

void main()
{
    int a = 0;
    try {
        a = 1; 
        scope(exit) a = 0; 
        throw new Exception("OOPS"); 
    } catch(Exception ex) {

    } finally {

    }
    writeln("A: ", a); 
}
