#!/usr/bin/rdmd

import std.stdio, 
       core.thread; 


class Interruptible
{
    void delegate() m_dg; 
    void function() m_fn; 
    private Call m_call; 
    private enum Call {NO, FN, DG}; 

    this (void delegate() dg)
    {
        m_dg = dg; 
        m_call = Call.DG;
    }

    this (void function() fn)
    {
        m_fn = fn; 
        m_call = Call.FN; 
    }

    void start() 
    {
        switch( m_call )
        {
            case Call.FN: 
                new Thread(m_fn).start(); 
                break; 
            case Call.DG: 
                new Thread(m_dg).start(); 
                break; 
            default: 
                break; 
        }
    }
}

void threadFunction()
{
    writeln("Hello, World!"); 
}

void main()
{
   new Interruptible(&threadFunction).start();  
}
