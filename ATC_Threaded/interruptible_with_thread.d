
alias getInt = Interruptible.getThis;

class Interruptible
{
    import core.thread,
           core.sys.posix.pthread;

    void function() m_fn; 
    void delegate() m_dg; 
    private Call m_call;
    private enum Call {NO, FN, DG};

    private Thread m_thr;
    private int priority;

    Interruptible child;

    private static Interruptible sm_this;


    this(void delegate() dg)
    {
        m_dg = dg; 
        m_call = Call.DG; 
    }

    this(void function() fn) 
    {
        m_fn = fn; 
        m_call = Call.FN; 
    }

    void setThis(Interruptible intr)
    {
        sm_this = intr;
    }

    static Interruptible getThis()
    {
        return sm_this;
    }

    void start()
    {
        m_thr = new Thread(&run);
        priority = Thread.getThis.priority;

        // If sm_this is null, we are not inside an interruptible section
        // currently. If we are inside an interruptible section, we need to set
        // the child of the parent interruptible to this. 
        if ( !(sm_this is null) )
        {
            Interruptible.getThis.child = this;
        }

        m_thr.start(); 
        m_thr.join();

        //cleanup
        m_thr.destroy();
        // no longer has a child.
        if ( !(sm_this is null) )
        {
            Interruptible.getThis.child = null;
        }
    }

    private void run()
    {
        Interruptible.setThis(this);
        Thread.getThis.priority = this.priority;
        if( pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, null) )
        {
            throw new Exception("Unable to set thread cancellation type");
        }
        if (m_call == Call.FN)
        {
            m_fn(); 
        }
        else if (m_call == Call.DG)
        {
            m_dg();
        }
    }

    void interrupt()
    {
        if( !_deferred )
        {
            if ( !(child is null) )
            {
                child.undeferrableInterrupt();
                if ( !(sm_this is null) )
                {
                    Interruptible.getThis.child = null;
                }
            }
            pthread_cancel(m_thr.id);
        }
        else 
        {
            _interrupt_pending = true;
        }
    }

    private void undeferrableInterrupt()
    {
        if ( !(child is null) )
        {
            child.undeferrableInterrupt; 
            if ( !(sm_this is null) )
            {
                Interruptible.getThis.child = null;
            }
        }
        pthread_cancel(m_thr.id);
    }

    private bool _deferred = false; 
    private bool _interrupt_pending = false; 

    @property bool deferred()
    {
        return _deferred;
    }

    @property void deferred(bool new_value)
    {
        if (new_value) // set this to true
        {
            //if (pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, null))
            // {
            //     throw new Exception("Unable to set thread cancellation type");
            //}
            _deferred = true;
        }

        else 
        {
            if (_interrupt_pending)
            {
                undeferrableInterrupt();
            }
            /*
               if (pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, null))
               {
               throw new Exception("Unable to set thread cancellation type");
               }
             */
            _deferred = false;
        }
    }

    void testCancel()
    {
        bool a = this.deferred;
        deferred = false; 
        pthread_testcancel();
        deferred = a;
    }

    void executeSafely(void delegate() fn)
    {
        if (pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, null))
        {
            throw new Error("Unable to set thread cancellation state");
        }
        fn();
        if (pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, null))
        {
            throw new Error("Unable to set thread cancellation state");
        }
    }
}

void*[] cleanup_array = []; 

import core.sys.posix.pthread;
pthread_cleanup* addCleanup(_pthread_cleanup_routine fn, void* arg)
{
    import core.memory; 
    pthread_cleanup* cleanup = cast(pthread_cleanup*)GC.malloc(pthread_cleanup.sizeof);

    cleanup_array ~= cast(void*)cleanup;

    cleanup.push(fn, arg);

    return cleanup;
}

/* debug function to print the cleanup_array */
private void output_array()
{
    import std.stdio; 
    int[] x; 
    foreach(void* elem; cleanup_array)
    {
        pthread_cleanup* elem2 = cast(pthread_cleanup*)elem;
        x ~= cast(int)elem2.buffer.__arg;
    }
    writeln("current array: ",x, "\n");
}

void remove(pthread_cleanup* cleanup)
{
    if (cleanup_array.length == 0)
    {
        throw new Exception("Nothing to pop from cleanup stack");
    }

    cleanup.pop(0);
    import std.algorithm.mutation; 
    uint index = getCleanupIndex(cleanup); 
    cleanup_array = cleanup_array[0..index];
}

private uint getCleanupIndex(pthread_cleanup* cleanup)
{
    foreach (uint i, void* __cleanup; cleanup_array)
    {
        if (cast(pthread_cleanup*)__cleanup == cleanup)
        {
            return i;
        }
    }
    throw new Exception("Element not found in array");
}







/* ------------------- Unittests ------------------------- */
unittest
{
    /** 
     * This basic example should test that a basic interrupt can be handled,
     * causing the interruptible section to get cancelled 
     **/
    import core.thread;

    __gshared Interruptible a;
    __gshared int x = 0; 

    void threadFunction()
    {
        while(true) {
            x = 1;
            Thread.sleep(200.msecs);
        }
    }

    void thread_to_spawn_interruptible()
    {
        a = new Interruptible(&threadFunction);  
        a.start(); 
    }

    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();
    Thread.sleep(1.seconds);
    auto time_a = MonoTime.currTime + 0.seconds;
    a.interrupt();
    mythread.join;
    auto time_b = MonoTime.currTime + 0.seconds; 
    assert(x == 1);
    assert(time_b <= time_a + 1.seconds);
}


unittest
{
    /** 
      This unittest should check that the priority of the calling thread is 
      correctly passed through to the Interruptible section
     */
    import core.thread;


    import core.sys.posix.sched : SCHED_FIFO, SCHED_OTHER, SCHED_RR; 

    void setScheduler(int scheduler_type, int scheduler_priority)
    {
        import core.sys.posix.sched : sched_param, sched_setscheduler; 
        sched_param sp = { sched_priority: scheduler_priority }; 
        int ret = sched_setscheduler(0, scheduler_type, &sp); 
        if (ret == -1) {
            throw new Exception("scheduler did not properly set");
        }
    }

    __gshared Interruptible a;
    __gshared int x = 0; 
    int prio = 70;

    void threadFunction()
    {
        while(true) {
            x = Thread.getThis.priority;
            Thread.sleep(200.msecs);
        }
    }

    void thread_to_spawn_interruptible()
    {
        Thread.getThis.priority = prio;
        a = new Interruptible(&threadFunction);  
        a.start(); 
    }

    //import RealTime : setScheduler, SCHED_FIFO;
    setScheduler(SCHED_FIFO, 50);
    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();
    Thread.sleep(1.seconds);
    auto time_a = MonoTime.currTime + 0.seconds;
    a.interrupt();
    mythread.join;
    auto time_b = MonoTime.currTime + 0.seconds; 
    assert(x == prio);
    assert(time_b <= time_a + 1.seconds);
}


unittest
{
    /** 
     * This basic example seeks to test that interrupts can occur within a nested
     * example, and that cancelling an outer interruptible section will also
     * cancel inner sections. 
     **/

    import core.thread;

    __gshared Interruptible athr;
    __gshared Interruptible bthr;
    __gshared Interruptible cthr;

    __gshared int xval = 0;
    int endValue = 100;

    void myThirdInterruptibleFunction()
    {
        while(true)
        {
            xval = endValue; 
            Thread.sleep(200.msecs);
        }
    }

    void mySecondInterruptibleFunction()
    {
        cthr = new Interruptible(&myThirdInterruptibleFunction);
        cthr.start();
        while(true)
        {
            xval = 10;
            Thread.sleep(200.msecs); 
        }
    }

    void interruptibleFunction()
    {
        bthr = new Interruptible(&mySecondInterruptibleFunction); 
        bthr.start(); 

        while(true)
        {
            xval = 20;
            Thread.sleep(200.msecs); 
        }
    }

    void thread_to_spawn_interruptible()
    {
        Thread.getThis.priority = 10;
        athr = new Interruptible(&interruptibleFunction);  
        athr.start(); 
    }

    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();
    Thread.sleep(1.seconds); 
    auto time_a = MonoTime.currTime + 0.seconds;
    athr.interrupt();
    mythread.join;
    auto time_b = MonoTime.currTime + 0.seconds;
    assert(xval == endValue);
    assert(time_b <= time_a + 1.seconds);
}


unittest
{
    /* Testing cleanup routines work properly, along with ability to pop
     * cleanup routines */

    import core.thread;

    __gshared Interruptible a;
    __gshared Interruptible b;
    __gshared Interruptible c;
    __gshared int[] myArray;

    extern (C) void thread_cleanup(void* arg) nothrow
    {
        int x = cast(int)arg;
        myArray ~= x;
    }

    void testfn()
    {
        auto a = addCleanup(&thread_cleanup, cast(void*)10);
        scope(exit) a.remove;
        auto b = addCleanup(&thread_cleanup, cast(void*)11);
        scope(exit) b.remove;
        auto c = addCleanup(&thread_cleanup, cast(void*)12);
        scope(exit) c.remove;
    }

    void myThirdInterruptibleFunction()
    {
        testfn();
        addCleanup(&thread_cleanup, cast(void*)3);
        addCleanup(&thread_cleanup, cast(void*)4);
        while(true)
        {
            Thread.sleep(100.msecs);
        }
    }

    void mySecondInterruptibleFunction()
    {
        addCleanup(&thread_cleanup, cast(void*)2);
        c = new Interruptible(&myThirdInterruptibleFunction);
        c.start();
        while(true)
        {
            Thread.sleep(100.msecs); 
        }
    }

    void interruptibleFunction()
    {
        addCleanup(&thread_cleanup, cast(void*)1);
        b = new Interruptible(&mySecondInterruptibleFunction); 
        b.start(); 

        while(true)
        {
            Thread.sleep(100.msecs); 
        }
    }

    void thread_to_spawn_interruptible()
    {
        Thread.getThis.priority = 10;
        a = new Interruptible(&interruptibleFunction);  
        a.start(); 
    }

    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();
    Thread.sleep(1.seconds); 
    b.interrupt();
    Thread.sleep(1.seconds); 
    a.interrupt();
    mythread.join;
    assert(myArray.length == 4);
    assert(myArray == [4,3,2,1]);
}
