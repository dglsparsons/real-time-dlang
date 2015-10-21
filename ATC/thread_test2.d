#!/usr/bin/rdmd

import core.thread; 
import std.stdio; 
import core.sys.posix.signal; 
import core.sys.posix.pthread; 
import core.atomic; 

shared pthread_t mythread; 
shared int n = 0; 

void main()
{
    auto a = new Thread(&myFunc); 
    a.start; 
    Thread.sleep(1.seconds); 
    while(1){
        Thread.sleep(5.seconds); 
        pthread_kill(mythread, 34); 
    }
}

void myFunc()
{
    mythread = pthread_self();
    sigaction_t action; 
    action.sa_handler = &handler; 
    sigemptyset(&action.sa_mask); 
    sigaction(34, &action, null); 
    while(1)
    {
        writeln("Thread doing work: ", n); 
        atomicOp!"+="(n, 1); 
        Thread.sleep(1.seconds); 
    }
}

extern (C) @nogc void handler(int signum) nothrow
{
    n = 0; 
}
