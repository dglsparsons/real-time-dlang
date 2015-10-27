#!/usr/bin/rdmd

import core.thread, 
       std.stdio, 
       core.sys.posix.signal, 
       std.conv,
       core.sys.posix.pthread; 

void enableInterruptableSections()
{
    sigaction_t action; 
    action.sa_handler = &sig_handler; 
    sigemptyset(&action.sa_mask); 
    sigaction(36, &action, null); 
}

extern (C) void sig_handler(int signum)
{
    throw new AsyncException(); 
}

class AsyncException : Exception
{
    this()
    {
        super(null); 
    }
}

class RTThread : Thread 
{
    bool interruptable = false; 

    this(void function() fn)
    {
        super(&fn); 
    }

    bool interrupt()
    {
        if (this.interruptable)
        {
            if (pthread_kill(m_addr, 36))
            {
                throw new Exception("Unable to signal the posix thread: "); 
            }
            return true; 
        } 
        else 
        {
            writeln("Attempted to interrupt thread ", m_addr, " but it is not interruptable"); 
            return false; 
        }
    }

    private: 
    void run()
    {
        threadFunc(); 
    }
}

void threadFunc()
{
    RTThread self = to!RTThread(Thread.getThis()); 
    self.interruptable = true; 
    try {
        while(true)
        {
            Thread.sleep(1.seconds); 
            writeln("Hello, I am a thread"); 
        }
    } catch (AsyncException e)
    self.interruptable = false; 
    while(true)
    {
        writeln("Thread is now down here"); 
        Thread.sleep(1.seconds); 
    }
}

void main()
{
    enableInterruptableSections(); 
    auto a = new RTThread(&threadFunc); 
    a.start(); 
    Thread.sleep(3.seconds); 
    a.interrupt; 
    while(true)
    {
        Thread.sleep(2.seconds); 
        a.interrupt; 
    }
}

