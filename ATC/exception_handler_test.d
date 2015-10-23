#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       core.sys.posix.signal, 
       core.sys.posix.pthread; 

void main()
{
    writeln("Main thread started with thread_id: ", pthread_self()); 
    new Thread(&threadFunc).start(); 
    //block signals 
    sigset_t set; 
    sigfillset(&set); 
    sigaddset(&set, SIGINT); 
    pthread_sigmask(SIG_BLOCK, &set, null); 
}

void threadFunc()
{
    try {
        writeln("New thread started with thread_id: ", pthread_self()); 

        //set up a sighandler
        sigaction_t action; 
        action.sa_handler = &sig_handler; 
        sigemptyset(&action.sa_mask); 
        sigaction(SIGINT, &action, null); 

        scope(exit) writeln("Unlocking a mutex for example"); 
        scope(exit) writeln("Unwind stuff here"); 

        while(1){
            writeln("Thread doing something"); 
            Thread.sleep(1.seconds); 
        }
    } 
    catch (Exception e) {}
    finally {
        //reset the sighandler

        sigset_t set; 
        sigemptyset(&set); 
        pthread_sigmask(SIG_BLOCK, &set, null); 
    }

    while(1) {
        writeln("Thread is processing down here"); 
        Thread.sleep(1.seconds); 
    }
}

extern (C) void sig_handler(int signum) 
{
    writeln("signal ", signum, " received in thread: ", pthread_self()); 
    throw new Exception("oops"); 
}
