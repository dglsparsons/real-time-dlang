#!/usr/bin/rdmd

import std.stdio, 
       core.thread, 
       core.sys.posix.pthread; 

void enableInterruptableSections()                                                                                                                                                                      
{                                                                                                                                                                                                       
    import core.sys.posix.signal: sigaction_t, sigemptyset, sigaction;                                                                                                                                  
    sigaction_t action;                                                                                                                                                                                 
    action.sa_handler = &sig_handler;                                                                                                                                                                   
    sigemptyset(&action.sa_mask);                                                                                                                                                                       
    sigaction(36, &action, null);                                                                                                                                                                       
}                                                                                                                                                                                                       

extern (C) @safe void sig_handler(int signum)                                                                                                                                                           
{                                                                                                                                                                                                       
    writeln("sig handler called"); 

    makeFiberYield(); 
}

@trusted void makeFiberYield()
{
    sigset_t x;
    sigemptyset (&x);
    sigaddset(&x, 36);
    sigprocmask(SIG_UNBLOCK, &x, null);

    // this will Segfault if you are not in a fiber.
    Fiber.getThis.yield; 
}

class myThread : Thread
{
    this()
    {
        super(&run);
    }

    void interrupt()
    {
        writeln("pthread_kill called: ", this.id);
        pthread_kill(this.id, 36);
    }

    private:
    void run()
    {
        new Fiber(&nestingFiber).call();
        while(true)
        {
            writeln("exited fiber loop");
            Thread.sleep(1.seconds);
        }
    }
}

void nestingFiber()
{
    new Fiber(&interruptibleSection).call();
    while(true)
    {
        Thread.sleep(1.seconds); 
        writeln("outer fiber loop");
    }
}

void interruptibleSection()
{
    while(true)
    {
        Thread.sleep(1.seconds);
        writeln("Hello, World!");
    }
}


void main()
{
    enableInterruptableSections();
    writeln("pthread_main: ", pthread_self());
    auto x = new myThread();
    x.start();
    Thread.sleep(5.seconds);

    x.interrupt();
    while(true){
        Thread.sleep(5.seconds);
        x.interrupt(); 
    }
}
