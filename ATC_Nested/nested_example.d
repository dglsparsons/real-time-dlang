#!/usr/bin/rdmd

import RealTime; 
import std.stdio; 

class myAsyncException : Exception
{
    int depth; 
    this(int d)
    {
        super(); 
        this.depth = d; 
    }

}

void main()
{
    void testfunction()
    {
        writeln("What the hell!"); 
    }

    auto aie = new myAsyncException(0); 
    try {
        auto exc = new myAsyncException(1); 
        try {
            testfunction();
            throw aie; 
        } catch (myAsyncException ex) {
            if (ex.depth == exc.depth)
                writeln("Depth 1");
            else 
                throw ex; 
        }
    } catch (myAsyncException ex) {
        if (ex.depth == aie.depth)
            writeln("Depth 0"); 
        else
            throw ex; 
    }

}
