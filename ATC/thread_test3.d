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
    Thread.sleep(3.seconds); 
    pthread_kill(mythread, 34); 
    thread_joinAll;
}

void myFunc()
{
    mythread = pthread_self();
    sigaction_t action; 
    action.sa_handler = &handler; 
    sigemptyset(&action.sa_mask); 
    sigaction(34, &action, null); 

    sigset_t set; 
    sigemptyset(&set); 
    sigaddset(&set, 34); 

    while(1)
    {
        pthread_sigmask(SIG_BLOCK, &set, null); // Block SIGINT
        writeln("Thread doing work: ", n); 
        atomicOp!"+="(n, 1); 
        Thread.sleep(1.seconds); 
        writeln("End of thread work"); 
        pthread_sigmask(SIG_UNBLOCK, &set, null); // Allow SIGINT
        // Might write out signal 34 received here
    }
}

extern (C) void handler(int signum)
{
    writeln("Signal ", signum, " Received"); 
    // I'm not sure how to terminate the thread
}
