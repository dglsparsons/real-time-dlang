alias getInt = Interruptible.getThis;

private import core.sys.posix.signal;

class Interruptible
{
    import core.sys.posix.pthread;
    private void function() m_fn;
    private void delegate() m_dg;
    private Call m_call;
    private enum Call {NO, FN, DG};

    private pthread_t m_threadId; 
    public ATCInterrupt m_error; 

    static private Interruptible sm_this = null;
    shared static Interruptible toThrow;
    package Interruptible parent = null;

    this(void function() fn )
    {
        m_fn = fn; 
        m_call = Call.FN;
        m_error = new ATCInterrupt(this); 
    }

    this(void delegate() dg )
    {
        m_dg = dg; 
        m_call = Call.DG;
        m_error = new ATCInterrupt(this); 
    }

    static Interruptible getThis() @nogc @safe nothrow
    {
        return sm_this;
    }

    private ATCInterrupt m_caughtError;

    void start() @trusted
    {
        import core.thread; 
        m_threadId = pthread_self;
        parent = sm_this;
        scope(exit) sm_this = parent;
        sm_this = this; 
        try 
        {
            if (m_call == Call.FN)
            {
                m_fn();
            }
            if (m_call == Call.DG)
            {
                m_dg();
            }
        } 
        catch (ATCInterrupt ex)
        {
            sigset_t __sigset_clear;
            sigemptyset(&__sigset_clear);
            sigaddset(&__sigset_clear, _SIGRTMIN); 
            sigprocmask(SIG_UNBLOCK, &__sigset_clear, null);

            m_caughtError = ex;
        }
        finally 
        {
            foreach(_clean; cleanup_fns)
            {
                _clean.exec;
            }
            if (!(m_caughtError is null))
            {
                if (m_caughtError.owner != this)
                {
                    throw m_caughtError;
                } 
            }
        }
    }

    private bool __deferred = false; 
    private bool __pending = false; 

    @property void deferred(bool newValue) @safe
    {
        if (!newValue) 
        {
            //reenabling should check if there are any interrupts pending.
            if (__pending)
            {
                __deferred = false;
                interrupt();
            }
        }
        __deferred = newValue;
    }

    @property bool deferred() nothrow @safe
    {
        return __deferred;
    }

    void interrupt() @trusted 
    {
        if (__deferred)
        {
            __pending = true;
        }
        else
        {
            import core.sys.posix.signal; 
            Interruptible.toThrow = cast(shared Interruptible)this;
            if (pthread_kill(m_threadId, _SIGRTMIN))
                throw new Exception("Unable to signal the interruptible section");
        }
    }

    public void testCancel()
    {
        if (__pending)
        {
            import core.sys.posix.signal; 
            Interruptible.toThrow = cast(shared Interruptible) this; 
            if (pthread_kill(m_threadId, _SIGRTMIN))
                throw new Exception("Unable to signal the interruptible section");
        }
    }

    private Cleanup[] cleanup_fns;

    import core.sys.posix.pthread;
    Cleanup addCleanup(void function(void*) fn, void* arg)
    {
        Cleanup __clean = Cleanup(fn, arg); 
        cleanup_fns = __clean ~ cleanup_fns;
        return __clean;
    }
    Cleanup addCleanup(void delegate(void*) dg, void* arg)
    {
        Cleanup __clean = Cleanup(dg, arg); 
        cleanup_fns = __clean ~ cleanup_fns;
        return __clean;
    }

    void removeCleanup(Cleanup cleanup)
    {
        if (cleanup_fns.length == 0) 
        {
            throw new Exception("Unable to remove");
        }
        foreach(int i, cln; cleanup_fns)
        {
            if (cleanup.fn == cln.fn)
            {
                cleanup_fns = i == cleanup_fns.length ? cleanup_fns[0..i]
                    : cleanup_fns[0..i] ~ cleanup_fns[i+1..$];
                break;
            }
        }
    }

    private bool previousDeferState;

    private void defer() @safe
    {
        if (! (parent is null) )
        {
            parent.defer;
        }
        previousDeferState = this.deferred;
        this.deferred = true;
    }
    private void restore() @safe
    {
        if (! (parent is null))
        {
            parent.restore;
        }
        this.deferred = previousDeferState;
    }

    void executeSafely(void delegate() fn) 
    {
        defer();
        scope(exit) restore();
        fn();
    }
}

struct Cleanup
{
    private void function(void*) fn;
    private void delegate(void*) dg;
    private void* arg;

    private Call m_call;
    private enum Call {NO, FN, DG};

    this(void delegate(void*) _fn, void* _arg)
    {
        dg = _fn; 
        arg = _arg;
        m_call = Call.DG;
    }

    this(void function(void*) _fn, void* _arg)
    {
        fn = _fn; 
        arg = _arg;
        m_call = Call.FN;
    }

    void exec()
    {
        if (m_call == Call.FN)
            fn(arg);
        if (m_call == Call.DG)
            dg(arg);
    }
}

import core.exception;
private class ATCInterrupt : Error
{
    Interruptible owner;
    this(Interruptible own)
    {
        super(null, null);
        owner = own;
    }
}

void enableInterruptibleSections()
{
    import core.sys.posix.signal: sigaction_t, sigemptyset, sigaction; 
    sigaction_t action; 
    action.sa_handler = &sig_handler; 
    sigemptyset(&action.sa_mask);
    sigaction(_SIGRTMIN, &action, null); 
}

private @property int _SIGRTMIN() nothrow @nogc 
{
    __gshared static int sig = -1;
    if (sig == -1) 
    {
        sig = __libc_current_sigrtmin();
    }
    return sig;
}

private extern (C) nothrow @nogc
{
    int __libc_current_sigrtmin();
}

private immutable sigset_t __sigset_clear = sigset_t([8589934592, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

extern (C) @safe void sig_handler(int signum) @nogc //nothrow
{
    if ( !(Interruptible.sm_this is null) )
    {
        throw Interruptible.toThrow.m_error;
    }
}


/* ------------------- Unittests ------------------------- */
unittest
{
    /** 
     * This basic example should test that a basic interrupt can be handled,
     * causing the interruptible section to get cancelled 
     **/
    import core.thread;
    enableInterruptibleSections;

    __gshared Interruptible a;
    __gshared int x = 0; 

    void threadFunction()
    {
        while(true) {
            x = 1;
            Thread.sleep(50.msecs);
        }
    }

    void thread_to_spawn_interruptible()
    {
        a = new Interruptible(&threadFunction);  
        a.start(); 
    }

    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();
    Thread.sleep(200.msecs);
    auto time_a = MonoTime.currTime + 0.seconds;
    a.interrupt();
    mythread.join;
    auto time_b = MonoTime.currTime + 0.seconds; 
    assert(x == 1);
    assert(time_b <= time_a + 200.msecs);
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
            Thread.sleep(50.msecs);
        }
    }

    void thread_to_spawn_interruptible()
    {
        Thread.getThis.priority = prio;
        a = new Interruptible(&threadFunction);  
        a.start(); 
    }

    enableInterruptibleSections;
    //import RealTime : setScheduler, SCHED_FIFO;
    setScheduler(SCHED_FIFO, 50);
    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();
    Thread.sleep(200.msecs);
    auto time_a = MonoTime.currTime + 0.seconds;
    a.interrupt();
    mythread.join;
    auto time_b = MonoTime.currTime + 0.seconds; 
    assert(x == prio);
    assert(time_b <= time_a + 200.msecs);
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
            Thread.sleep(50.msecs);
        }
    }

    void mySecondInterruptibleFunction()
    {
        cthr = new Interruptible(&myThirdInterruptibleFunction);
        cthr.start();
        assert(false);
    }

    void interruptibleFunction()
    {
        bthr = new Interruptible(&mySecondInterruptibleFunction); 
        bthr.start(); 
        assert(false);
    }

    void thread_to_spawn_interruptible()
    {
        Thread.getThis.priority = 10;
        athr = new Interruptible(&interruptibleFunction);  
        athr.start(); 
    }

    enableInterruptibleSections;
    auto mythread = new Thread(&thread_to_spawn_interruptible); 
    mythread.start();
    Thread.sleep(100.msecs); 
    auto time_a = MonoTime.currTime + 0.seconds;
    athr.interrupt();
    mythread.join;
    auto time_b = MonoTime.currTime + 0.seconds;
    assert(xval == endValue);
    assert(time_b <= time_a + 100.msecs);
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

    void thread_cleanup(void* arg) nothrow
    {
        int x = cast(int)arg;
        myArray ~= x;
    }

    void testfn()
    {
        auto p = getInt.addCleanup(&thread_cleanup, cast(void*)10);
        scope(exit) getInt.removeCleanup(p);
        auto q = getInt.addCleanup(&thread_cleanup, cast(void*)11);
        scope(exit) getInt.removeCleanup(q);
        auto r = getInt.addCleanup(&thread_cleanup, cast(void*)12);
        scope(exit) getInt.removeCleanup(r);
    }

    void myThirdInterruptibleFunction()
    {
        testfn();
        getInt.addCleanup(&thread_cleanup, cast(void*)3);
        getInt.addCleanup(&thread_cleanup, cast(void*)4);
        while(true)
        {
            Thread.sleep(50.msecs);
        }
    }

    void mySecondInterruptibleFunction()
    {
        getInt.addCleanup(&thread_cleanup, cast(void*)2);
        c = new Interruptible(&myThirdInterruptibleFunction);
        c.start();
    }

    void interruptibleFunction()
    {
        getInt.addCleanup(&thread_cleanup, cast(void*)1);
        b = new Interruptible(&mySecondInterruptibleFunction); 
        b.start(); 

        while(true)
        {
            Thread.sleep(50.msecs); 
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
    Thread.sleep(100.msecs); 
    b.interrupt();
    Thread.sleep(100.msecs); 
    a.interrupt();
    mythread.join;
    assert(myArray.length == 4);
    assert(myArray == [4,3,2,1]);
}


unittest 
{
    /** Checking the ability to testCancel a function inside an infinite loop, 
      and the ability to defer interrupts */

    import core.thread;

    __gshared Interruptible a;
    __gshared int x;
    int maxVal = 2_000_000;

    void interruptThis()
    {
        Thread.sleep(50.msecs);
        a.interrupt();
    }

    void interruptibleFunction() 
    {
        getInt.deferred = true; 
        for(int i = 0; i < maxVal; i++)
        {
            x = i;
            i = i*x;
            getInt.testCancel;
        }
    }

    enableInterruptibleSections();
    new Thread(&interruptThis).start();
    a = new Interruptible(&interruptibleFunction); 
    a.start();
    assert(x != maxVal);
}

unittest
{
    /* checking the ability to cancel a nested interruptible section, even if
     * the nested interruptible section is set to defer interrupts. - note,
     * with executeSafely, it is possible to defer the inner cancel too.
     */
    import core.thread;

    __gshared Interruptible a;
    __gshared int x; 
    int maxVal = 2_000_000;

    void interruptThis()
    {
        Thread.sleep(50.msecs);
        a.interrupt();
    }

    void interruptibleFunction() 
    {

        getInt.deferred = true; 
        for(int i = 0; i < maxVal; i++)
        {
            void update() 
            {
                Thread.sleep(10.msecs);
                x = i;
                i = i * 7;
            }
            getInt.executeSafely(&update);
        }

    }

    void outerInterruptible() 
    {
        //getInt.deferred = true;
        Interruptible b;

        void initInterruptible() 
        {
            b = new Interruptible(&interruptibleFunction);
        }
        getInt.executeSafely(&initInterruptible);
        b.start();
    }

    enableInterruptibleSections;
    new Thread(&interruptThis).start();
    a = new Interruptible(&outerInterruptible);
    a.start();
    assert(x != maxVal);
}



unittest
{
    /** Check that deferrable sections cancel when we stop being deferred
     */
    import core.thread;
    __gshared Interruptible myIntr;
    __gshared bool boolValue = false;

    void intSection()
    {
        getInt.deferred = true;
        Thread.sleep(2.seconds);    
        boolValue = true;
        getInt.deferred = false;
        assert(false); // should never get here
    }

    void intThis()
    {
        Thread.sleep(50.msecs);
        myIntr.interrupt(); // should get deferred
    }

    //Thread.sleep(50.msecs);
    enableInterruptibleSections;
    myIntr = new Interruptible(&intSection);
    new Thread(&intThis).start();
    myIntr.start();
    assert(boolValue);
}


unittest
{
    /** Unittest to determine testCancel works properly when a cancel has 
      been deferred. */

    import core.thread;

    __gshared Interruptible a;

    void intThis()
    {
        Thread.sleep(10.msecs); 
        a.interrupt();
    }

    void intSection()
    {
        getInt.deferred = true; 
        Thread.sleep(50.msecs);
        getInt.testCancel;
    }

    a = new Interruptible(&intSection); 
    new Thread(&intThis).start();
    a.start();
}
