alias getInt = Interruptible.getThis;

class Interruptible
{
    import core.thread, 
           core.sys.posix.pthread, 
           core.sync.condition, 
           core.sync.mutex; 

    private void delegate() m_dg;
    private void function() m_fn;
    private Call m_call;
    private enum Call {NO, FN, DG};

    private pthread_t m_thr;
    private int priority;

    private static pthread_t sm_thr; 
    private static Interruptible sm_this;

    Interruptible child;

    this (void delegate() dg)
    {
        m_dg = dg; 
        m_call = Call.DG;
    }

    this (void function() fn)
    {
        m_fn = fn; 
        m_call = Call.FN; 
    }

    void start() 
    {
        pthread_attr_t attr; 
        if(pthread_attr_init(&attr))
        {
            throw new Error("Unable to initialise thread attributes"); 
        }

        if (!(Interruptible.sm_this is null))
        {
            // this means we are inside an interruptible section already.
            // Then we need to set the parent Interruptibles child, allowing cancels
            // to propagate.
            Interruptible.getThis.child = this;
        }

        if (pthread_create(&m_thr, &attr, &run, cast(void*)this))
        {
            throw new Error("Unable to create thread"); 
        }

        auto a = sched_getscheduler(0);

        if (pthread_setschedprio(m_thr, getParentPriority))
        {
            throw new Error("Unable to correctly set thread priority"); 
        }


        pthread_join(m_thr, null); 

        m_thr.destroy;

        if ( !(sm_this is null) )
        {
            Interruptible.getThis.child = null;
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
            pthread_cancel(m_thr);
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
        pthread_cancel(m_thr);
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

    void testCancel()
    {
        bool a = this.deferred;
        deferred = false; 
        pthread_testcancel();
        deferred = a;
    }


    private int getParentPriority()
    {
        if (Interruptible.sm_thr == 0) 
        {
            // Then we need the parent thread. 
            return Thread.getThis.priority;
        }
        else 
        {
            pthread_t parent_m_addr = pthread_self();
            // We need to get the parent pthread
            int         policy;
            sched_param param;
            if (auto err = pthread_getschedparam(parent_m_addr, &policy, &param))
            {
                //if (!atomicLoad(m_isRunning)) return PRIORITY_DEFAULT;
                throw new ThreadException("Unable to get thread priority");
            }
            return param.sched_priority;
        }
    }


    static void setTid(pthread_t inr)
    {
        sm_thr = inr; 
    }

    static void setThis(Interruptible intr)
    {
        sm_this = intr;
    }

    static Interruptible getThis()
    {
        return sm_this; 
    }

    pthread_t getThreadID()
    {
        return m_thr;
    }
}

extern (C) void* run(void* arg) 
{
    import core.sys.posix.pthread; 

    Interruptible obj = cast(Interruptible)(cast(void*)arg);

    Interruptible.setTid(obj.getThreadID); 
    Interruptible.setThis(obj);

    int oldtype; 
    pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, &oldtype); 

    if (obj.m_call == obj.Call.FN)
    {
        obj.m_fn(); 
    }
    else if (obj.m_call == obj.Call.DG)
    {
        obj.m_dg(); 
    }
    return null; 
}



/** Cleanup Functions **/


void*[] cleanup_array = []; 

import core.sys.posix.pthread;
pthread_cleanup* addCleanup(_pthread_cleanup_routine fn, void* arg)
{
    import core.memory; 
    pthread_cleanup* cleanup = cast(pthread_cleanup*)GC.malloc(pthread_cleanup.sizeof);

    cleanup_array ~= cast(void*)cleanup;

    cleanup.push(fn, arg);

    import std.stdio;
    writeln("Pushing extra cleanup: ", cast(int)arg);

    writeln("cleanup_array length:", cleanup_array.length);
    output_array();
    return cleanup;
}

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
    import std.stdio; 
    writeln("Popping extra cleanup: ", cast(int)cleanup.buffer.__arg);
    import std.algorithm.mutation; 
    uint index = getCleanupIndex(cleanup); 
    cleanup_array = cleanup_array[0..index];

    writeln("cleanup_array length:", cleanup_array.length);
    output_array();
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
