
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

    //private pthread_cleanup cleanup = void; 




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
        pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, null);
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

    return cleanup;
}

void remove(pthread_cleanup* cleanup)
{
    if ( cleanup != cleanup_array[$] )
    {
        throw new Exception("Last items on the cleanup_stack should be popped first!");
    }
    cleanup.pop(0);
    import std.stdio; 
    writeln("Popping extra cleanup: ", cast(int)cleanup.buffer.__arg);

}

void removeCleanup(int position)
{
    //pthread_cleanup* obj = cast(pthread_cleanup*)cleanup_array[position];
    //obj.pop(0);
    //cleanup_array = cleanup_array[0..position-1] ~ cleanup_array[position+1..$];
}
