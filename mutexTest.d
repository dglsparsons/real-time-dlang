#!/usr/bin/rdmd

import std.stdio; 
import core.thread; 
import core.sync.mutex; 

__gshared Mutex myMutex; 

void lockMutex()
{
    writeln("Waiting for lock"); 
    myMutex.lock(); 
    writeln("Locked mutex"); 
    Thread.sleep(5.seconds); 
    myMutex.unlock(); 
}

void unlockMutex()
{
    myMutex.unlock(); 
    writeln("Unlocked mutex"); 
}

void main()
{
    myMutex = new Mutex(); 

    new Thread(&lockMutex).start(); 
    new Thread(&lockMutex).start(); 
    Thread.sleep(5.seconds); 
    //new Thread(&unlockMutex).start(); 

    thread_joinAll; 
}
