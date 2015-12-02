#!/usr/bin/rdmd

import core.thread, 
       std.stdio; 

void main()
{
    Fiber.getThis.yield; 
}
