#!/usr/bin/rdmd

import std.stdio; 
import core.thread;
import core.sys.posix.pthread; 
import core.sync.mutex; 

shared bool should_exit = false; 
__gshared MutexWithPrioInheritance myMutex;

class HighPriorityThread : Thread
{
    this(){
        super(&run); 
    }

private: 
    void run(){
        this.priority(48);
        writeln("High Priority Thread has Started"); 
        //should_exit = true; 
        myMutex.lock(); 
        writeln("High priority thread has aquired lock!"); 
        myMutex.unlock(); 
    }
}

class LowPriorityThread : Thread
{
    this(){
        super(&run); 
    }

private: 
    void run(){
        this.priority(1); 
        writeln("Low Priority Thread has Started"); 
        //lock the mutex
        myMutex.lock; 
        writeln("Low Priority has locked the Mutex "); 
        while(!should_exit) {
            //loop forever
        }
        writeln("Low Priority has unlocked the Mutex"); 
        myMutex.unlock;
    }
}

class MediumPriorityThread : Thread 
{
    this(){
        super(&run); 
    }

private: 
    void run(){
        this.priority(2); 
        writeln("Medium Priority Thread has Started"); 
        while(true) {
            // Loop forever
        }
        writeln("Medium priority thread has finished"); 
    }
}

class MutexWithPrioInheritance : Mutex 
{
    this() nothrow @trusted {
        version( Windows )
        {
            InitializeCriticalSection( &m_hndl );
        }
        else version( Posix )
        {
            pthread_mutexattr_t attr = void;

            if( pthread_mutexattr_init( &attr ) )
                throw new SyncError( "Unable to initialize mutex" );
            scope(exit) pthread_mutexattr_destroy( &attr );

            if( pthread_mutexattr_settype( &attr, PTHREAD_MUTEX_RECURSIVE ) )
                throw new SyncError( "Unable to initialize mutex" );

            if (pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT))
                throw new SyncError("Unable to initialize prio inheritance"); 

            if( pthread_mutex_init( &m_hndl, &attr ) )
                throw new SyncError( "Unable to initialize mutex" );
        }
        m_proxy.link = this;
        this.__monitor = &m_proxy;
    }
private: 
    pthread_mutex_t m_hndl;
    MonitorProxy m_proxy;

}

void main()
{
    // Set the scheduler
    sched_param sp = { sched_priority: 50 }; 
    int ret = sched_setscheduler(0, SCHED_FIFO, &sp); 
    if (ret == -1) {
        throw new Exception("scheduler did not properly set");
    }

    // Create a mutex
    myMutex = new MutexWithPrioInheritance(); 

    // Start a low prio thread to lock the mutex and do something for ages. 
    // Medium priority to preempt the low priority
    // High priority to see if the inversion works

    new LowPriorityThread().start(); 
    Thread.sleep(1.seconds); 
    new MediumPriorityThread().start; 
    Thread.sleep(1.seconds); 
    new HighPriorityThread().start(); 

    thread_joinAll; 
}
