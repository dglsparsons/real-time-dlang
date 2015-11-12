#!/usr/bin/rdmd

import std.stdio;


class A 
{
    private string output = "Hello, World";
    void run()
    {
        writeln(output); 
    }
}


class B : private A
{
    void run()
    {
        super();
    }
}
