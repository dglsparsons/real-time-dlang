#!/usr/bin/rdmd

import RealTime; 
        import std.stdio; 

class myAsyncException : AsyncException
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
    auto aie = new myAsyncException(0); 
    try {
        auto exc = new myAsyncException(1); 
        try {
            throw aie; 
        } catch (myAsyncException ex) {
            if (ex.depth == exc.depth)
                writeln("WOO");
            else 
                throw ex; 
        }
    } catch (myAsyncException ex) {
        if (ex.depth == aie.depth)
            writeln("LEL"); 
        else
            throw ex; 
    }

}
