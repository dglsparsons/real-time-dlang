#!/usr/bin/rdmd

import std.stdio; 

class myClass 
{
    string a = "Hello"; 

    void start()
    {
        dg(this); 
    }
}

void dg(myClass x)
{
    writeln(x.a); 
}

void main()
{
    new myClass().start(); 
}
