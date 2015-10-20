#!/usr/bin/rdmd

import core.thread; 
import std.stdio; 
import core.sys.posix.signal; 
import std.conv; 
import core.sys.posix.pthread; 
import core.atomic; 

shared pthread_t something; 

void main()
{
    auto a = new Thread(&myFunc); 
    a.start; 
    Thread.sleep(1.seconds); 
    writeln("A: ", something); 
    while(1){
        Thread.sleep(5.seconds); 
        pthread_kill(something, 34SIGRTMIN); 
    }
}

shared int n = 0; 

void myFunc()
{
    something = pthread_self();
    signal(34, &handler); 
    while(1)
    {
        writeln("Thread doing smth: ", n); 
        atomicOp!"+="(n, 1); 
        Thread.sleep(1.seconds); 
    }
}

extern (C) @nogc void handler(int signum) nothrow
{
    n = 0; 
}
