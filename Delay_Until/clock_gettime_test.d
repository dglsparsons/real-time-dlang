#!/usr/bin/rdmd

import std.stdio; 
import core.time; 
import core.sys.posix.time; 


void main ()
{
    timespec ts; 
    if (clock_gettime(CLOCK_MONOTONIC, &ts)) {
        throw new Exception("Failed to get the time"); 
    }
    writeln("Clock: ", ts); 
}
