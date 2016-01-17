
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

    private pthread_cleanup cleanup; 

    extern (C) void addCleanup(void function(void*) fn, void* arg)
    {
        this.cleanup.push(&fn, cast(void*)3);
    }

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
