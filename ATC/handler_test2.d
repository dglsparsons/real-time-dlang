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

    sigaction_t action; 
    action.sa_handler = &handler; 
    sigemptyset(&action.sa_mask); 
    sigaction(2, &action, null); 

    while(1){
        Thread.sleep(10.seconds); 
    } // loop forever
}

void threadFunc()
{
    myThread = pthread_self(); 
    //pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, null); 
    pthread_setcanceltype(PTHREAD_CANCEL_DEFERRED, null); 
    writeln("new thread: ", pthread_self()); 
    Thread.sleep(2.seconds); 
    while(1){
        writeln("Hello, i am new thread"); 
        Thread.sleep(500.msecs); 
        pthread_testcancel(); 
    } // loop forever
}

extern (C) void handler(int signum)
{
    writeln("Cancelling thread ", myThread, " from ", pthread_self()); 
    pthread_cancel(myThread); 
    writeln("Worked!"); 
    new Thread(&threadFunc).start(); 
}
