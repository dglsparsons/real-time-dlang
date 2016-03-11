#!/usr/bin/rdmd 

import core.thread, std.process;

void main()
{
    while(true)
    {
        Thread.sleep(30.seconds); 
        executeShell("make cbs"); 
    }
}
