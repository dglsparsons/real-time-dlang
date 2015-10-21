#!/usr/bin/rdmd

import std.conv; 
import core.sys.posix.signal; 

void main(string[] args)
{
    immutable int first = to!int(args[1]); 
    kill(first, 2); 
}
