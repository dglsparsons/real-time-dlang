#!/usr/bin/rdmd

import std.stdio; 
import core.sys.posix.signal; 
import core.thread; 

int n; 

extern (C) @nogc void handler(int signum) nothrow
{
    printf("signal %d received - counter reset\n", signum); 
    n = 0; 
}


void main()
{
    signal(SIGINT, &handler); 
    while(1) 
    {
        writeln("Working: ", n++); 
        Thread.sleep(1.seconds); 
    }
}
