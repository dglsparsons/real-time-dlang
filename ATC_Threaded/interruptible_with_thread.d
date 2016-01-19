
alias self = Interruptible.getThis;

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
        if ( !(child is null) )
        {
            child.interrupt();
            if ( !(sm_this is null) )
            {
                Interruptible.getThis.child = null;
            }
        }
        pthread_cancel(m_thr.id);
    }

    private bool _deferred; 

    @property bool deferred()
    {
        return _deferred;
    }

    @property void deferred(bool new_value)
    {
        if (new_value) // set this to true
        {
            if (pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, null))
            {
                throw new Exception("Unable to set thread cancellation type");
            }
            _deferred = true;
        }
        else 
        {
            if (pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, null))
            {
                throw new Exception("Unable to set thread cancellation type");
            }
            _deferred = false;
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
