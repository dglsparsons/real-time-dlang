#!/usr/bin/rdmd

import core.thread; 
import core.sys.posix.signal; 
import core.sys.posix.pthread; 
import std.stdio; 

shared pthread_t myThread; 

void main()
{
    new Thread(&threadFunc).start(); 
    writeln("Main thread: ", pthread_self()); 
    //signal(SIGINT, &handler); 
    while(1){
        Thread.sleep(1.seconds); 
        pthread_kill(myThread, 2); 
    } // loop forever
}

void threadFunc()
{
    myThread = pthread_self(); 
    writeln("new thread: ", pthread_self()); 
    signal(SIGINT, &handler); 
    while(1){} // loop forever
}

extern (C) @nogc nothrow void handler(int signum)
{
    printf("%i in thread %lu\n",signum, pthread_self()); 
    signal(SIGINT, &handler); 
}
