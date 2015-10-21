#!/usr/bin/rdmd 

import std.stdio; 
import core.sync.mutex; 
import core.sys.posix.signal; 
import core.thread; 
import core.sys.posix.pthread; 

__gshared Mutex m ; 
shared pthread_t threadid; 

void main()
{

    m = new Mutex(); 
    new Thread(&threadFunc).start(); 
    Thread.sleep(1.seconds); 
    sigset_t set; 
    sigemptyset(&set); 
    sigaddset(&set, 34); 
    sigaddset(&set, 2); 
    pthread_sigmask(SIG_BLOCK, &set, null); 
    writeln("Main waiting for mutex!"); 
    m.lock(); 
    writeln("Main thread got mutex!"); 
}

extern (C) void handler(int signum)
{
    printf("Hello\n"); 
    pthread_cancel(threadid); 
}

void threadFunc()
{
    pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, null); 
    threadid = pthread_self(); 
    // Set up a signal handler. 
    sigaction_t action; 
    action.sa_handler = &handler; 
    sigemptyset(&action.sa_mask); 
    sigaction(2, &action, null); 
    //signal(SIGINT, &handler); 

    m.lock(); 
    scope(exit) m.unlock();

    while(1){
        writeln("test"); 
        Thread.sleep(1.seconds); 
        pthread_testcancel();
    }
}
